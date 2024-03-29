
//
//  Reflector.swift
//  Retrolux
//
//  Created by Christopher Bryan Henderson on 7/12/16.
//  Copyright © 2016 Bryan. All rights reserved.
//

import Foundation

open class Reflector {
    open var cache: [ObjectIdentifier: [Property]] = [:]
    open var lock = OSSpinLock()
    open class var shared: Reflector {
        struct Static {
            static let instance = Reflector()
        }
        return Static.instance
    }
    
    public init() {}
    
    open func convert(fromJSONArrayData arrayData: Data, to type: Reflectable.Type) throws -> [Reflectable] {
        let objects_any: Any
        do {
            objects_any = try JSONSerialization.jsonObject(with: arrayData, options: [])
        } catch {
            throw ReflectorSerializationError.invalidJSONData(error)
        }
        guard let objects = objects_any as? [[String: Any]] else {
            assert(objects_any as? [String: Any] != nil)
            throw ReflectorSerializationError.expectedArrayRootButGotDictionaryRoot(type: type)
        }
        return try convert(fromArray: objects, to: type)
    }
    
    open func convert(fromJSONDictionaryData dictionaryData: Data, to type: Reflectable.Type) throws -> Reflectable {
        let object_any: Any
        do {
            object_any = try JSONSerialization.jsonObject(with: dictionaryData, options: [])
        } catch {
            throw ReflectorSerializationError.invalidJSONData(error)
        }
        guard let object = object_any as? [String: Any] else {
            assert(object_any as? [Any] != nil)
            throw ReflectorSerializationError.expectedDictionaryRootButGotArrayRoot(type: type)
        }
        return try convert(fromDictionary: object, to: type)
    }
    
    open func convertToJSONDictionaryData(from instance: Reflectable) throws -> Data {
        let dictionary = try convertToDictionary(from: instance)
        return try JSONSerialization.data(withJSONObject: dictionary, options: [])
    }
    
    open func convertToJSONArrayData(from instances: [Reflectable]) throws -> Data {
        let array = try convertToArray(from: instances)
        return try JSONSerialization.data(withJSONObject: array, options: [])
    }
    
    open func convert(fromArray array: [[String: Any]], to type: Reflectable.Type) throws -> [Reflectable] {
        var output: [Reflectable] = []
        for dictionary in array {
            output.append(try convert(fromDictionary: dictionary, to: type))
        }
        return output
    }
    
    open func convert(fromDictionary dictionary: [String: Any], to type: Reflectable.Type) throws -> Reflectable {
        let instance = type.init()
        let properties = try reflect(instance)
        for property in properties {
            let rawValue = dictionary[property.mappedTo]
            try instance.set(value: rawValue, for: property)
        }
        return instance
    }
    
    open func convertToArray(from instances: [Reflectable]) throws -> [[String: Any]] {
        var output: [[String: Any]] = []
        for instance in instances {
            output.append(try convertToDictionary(from: instance))
        }
        return output
    }
    
    open func convertToDictionary(from instance: Reflectable) throws -> [String: Any] {
        var dictionary: [String: Any] = [:]
        let properties = try reflect(instance)
        for property in properties {
            dictionary[property.mappedTo] = try instance.value(for: property)
        }
        return dictionary
    }
    
    fileprivate func getMirrorChildren(_ mirror: Mirror, parentMirror: Mirror?) throws -> [(label: String, valueType: Any.Type)] {
        var children = [(label: String, valueType: Any.Type)]()
        if let superMirror = mirror.superclassMirror, superMirror.subjectType is Reflectable.Type {
            children = try getMirrorChildren(superMirror, parentMirror: mirror)
        } else if parentMirror != nil {
            if mirror.subjectType is ReflectableSubclassingIsAllowed.Type == false {
                throw ReflectionError.subclassingNotAllowed(mirror.subjectType)
            }
        }
        
        // Purposefully ignores labels that are nil
        return children + mirror.children.flatMap {
            guard let label = $0.label else {
                return nil
            }
            return (label, type(of: $0.value))
        }
    }
    
    open func reflect(_ instance: Reflectable) throws -> [Property] {
        OSSpinLockLock(&lock)
        defer {
            OSSpinLockUnlock(&lock)
        }
        
        let cacheID = ObjectIdentifier(type(of: instance))
        if let cached = cache[cacheID] {
            return cached
        }
        
        var properties = [Property]()
        let subjectType = type(of: instance)
        
        var ignored = Set(subjectType.ignoredProperties)
        let ignoreErrorsFor = Set(subjectType.ignoreErrorsForProperties)
        let mapped = subjectType.mappedProperties
        let transformed = subjectType.transformedProperties
        
        let children = try getMirrorChildren(Mirror(reflecting: instance), parentMirror: nil)
        let propertyNameSet: Set<String> = Set(children.map({ $0.label }))
        
        // Automatically treat read-only properties as ignored.
        let readOnly = propertyNameSet.filter {
            isReadOnly(property: $0, instance: instance)
        }
        ignored.formUnion(readOnly)
        
        // We *could* silently ignore the users request to ignore a non-existant property, but it's possible that
        // they simply misspelled it. Raise an error just to be safe.
        if let ignoredButNotImplemented = ignored.subtracting(propertyNameSet).first {
            throw ReflectionError.cannotIgnoreNonExistantProperty(
                propertyName: ignoredButNotImplemented,
                forClass: subjectType
            )
        }
        
        // A non-existant property is not considered an error that can be ignored. It probably indicates a mistake
        // on the user's part.
        if let optionalButNotImplemented = ignoreErrorsFor.subtracting(propertyNameSet).first {
            throw ReflectionError.cannotIgnoreErrorsForNonExistantProperty(
                propertyName: optionalButNotImplemented,
                forClass: subjectType
            )
        }
        
        // Check if the user has requested to completely ignore a property AS WELL as ignore only the errors.
        if let ignoredAndOptional = ignored.intersection(ignoreErrorsFor).first {
            throw ReflectionError.cannotIgnoreErrorsAndIgnoreProperty(
                propertyName: ignoredAndOptional,
                forClass: subjectType
            )
        }
        
        // Check if the user has requested to remap a property that doesn't exist.
        if let mappedButNotImplemented = Set(mapped.keys).subtracting(propertyNameSet).first {
            throw ReflectionError.cannotMapNonExistantProperty(
                propertyName: mappedButNotImplemented,
                forClass: subjectType
            )
        }
        
        if let transformedButNotImplemented = Set(transformed.keys).subtracting(propertyNameSet).first {
            throw ReflectionError.cannotTransformNonExistantProperty(
                propertyName: transformedButNotImplemented,
                forClass: subjectType
            )
        }
        
        // We cannot possibly map one property to multiple values.
        let excessivelyMapped = mapped.filter { k1, v1 in
            mapped.contains {
                v1 == $1 && k1 != $0
            }
        }
        if !excessivelyMapped.isEmpty {
            let pickOne = excessivelyMapped.first!.1
            let propertiesForIt = excessivelyMapped.filter { $1 == pickOne }.map { $0.0 }
            throw ReflectionError.mappedPropertyConflict(
                properties: propertiesForIt,
                conflictKey: pickOne,
                forClass: subjectType
            )
        }
        
        // Ignoring and mapping a property doesn't make sense and might indicate a user error.
        if let ignoredAndMapped = ignored.intersection(mapped.keys).first {
            throw ReflectionError.cannotMapAndIgnoreProperty(
                propertyName: ignoredAndMapped,
                forClass: subjectType
            )
        }
        
        if let transformedAndIgnored = ignored.intersection(transformed.keys).first {
            throw ReflectionError.cannotTransformAndIgnoreProperty(
                propertyName: transformedAndIgnored,
                forClass: subjectType
            )
        }
        
        for (label, valueType) in children {
            if ignored.contains(label) {
                continue
            }
            
            var transformer: ValueTransformer?
            if let custom = transformed[label] {
                transformer = custom
            } else {
                transformer = ReflectableTransformer(reflector: self)
            }
            
            var transformerMatched = false
            guard let type = PropertyType.from(valueType, transformer: transformer, transformerMatched: &transformerMatched) else {
                // We don't know what type this property is, so it's unsupported.
                // The user should probably add this to their list of ignored properties if it reaches this point.
                
                throw ReflectionError.propertyNotSupported(
                    propertyName: label,
                    valueType: valueType,
                    forClass: subjectType
                )
            }
            
            if !transformerMatched {
                // Don't save to the property.
                transformer = nil
            }
            
            // TODO: At this point, we should validate that the transformer, if it exists, is being used properly
            // in the property type.
            
            guard instance.responds(to: Selector(label)) else {
                // This property cannot be seen by the Objective-C runtime.
                
                switch type {
                case .optional(let wrapped):
                    // Optional numeric primitives (i.e., Int?) cannot be bridged to Objective-C as of Swift 3.1.0.
                    switch wrapped {
                    case .number(let wrappedType):
                        throw ReflectionError.optionalNumericTypesAreNotSupported(
                            propertyName: label,
                            unwrappedType: wrappedType,
                            forClass: subjectType
                        )
                    case .bool:
                        throw ReflectionError.optionalNumericTypesAreNotSupported(
                            propertyName: label,
                            unwrappedType: Bool.self,
                            forClass: subjectType
                        )
                    default:
                        break
                    }
                default:
                    break
                }
                
                // We have no clue what this property type is.
                throw ReflectionError.propertyNotSupported(
                    propertyName: label,
                    valueType: valueType,
                    forClass: subjectType
                )
            }
            
            let required = !ignoreErrorsFor.contains(label)
            let finalMappedKey = mapped[label] ?? label
            let property = Property(type: type, name: label, required: required, mappedTo: finalMappedKey, transformer: transformer)
            properties.append(property)
        }
        
        cache[cacheID] = properties
        
        return properties
    }
    
    fileprivate func isReadOnly(property: String, instance: Reflectable) -> Bool {
        guard let objc_property = class_getProperty(type(of: instance), property) else {
            return false
        }
        guard let c_attributes = property_getAttributes(objc_property) else {
            return false
        }
        let attributes = String(cString: c_attributes, encoding: String.Encoding.utf8)!
        return attributes.components(separatedBy: ",").contains("R")
    }
}
