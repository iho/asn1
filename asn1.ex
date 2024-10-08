#!/usr/bin/env elixir
  defmodule ASN1SwiftCodeGenerator do

    def var_decl(index, type) do
        """
        var w#{index} : #{variable_type(index, type)} = []
        """
    end
    def generate_swift_code(identifiers, default, type) do
      variable_names = Enum.reverse(identifiers)
      if length(identifiers) < 2 do
        default
      else
      ser = generate_serialize_code(tl(identifiers))
      IO.inspect(type)
      methods = generate_method(length(identifiers), identifiers, length(variable_names), type)
      """
      @inlinable init(derEncoded root: ASN1Node,
      withIdentifier identifier: ASN1Identifier) throws {
    let res = #{methods}

    self.w = res
      }
    #{ser}
    """
    end
    end

    def generate_method(len, identifiers, level, type) do
        if level == 0 do
         """
            contentsOf: try DER.sequence(of: #{type}.self, identifier: .sequence, rootNode: node0)
        """
        else
        dd =hd(identifiers)
        winner =  if( len == length(identifiers), do:  "root", else: "node#{level}")
        case dd do
            ".sequence" -> """
            try DER.sequence(#{winner }, identifier: .sequence) { nodes#{level} in \n
             #{var_decl(level, type)}
              while let node#{level-1} = nodes#{level}.next() {
               w#{level}.append(
                #{generate_method(len, tl(identifiers), level - 1, type )}
               )
            }
            return w#{level}\n
              }
            """
            ".set" -> """
            try DER.set(#{winner}, identifier: .set) { nodes#{level} in \n
            #{var_decl(level, type)}
            while let node#{level-1} = nodes#{level}.next() {
            w#{level}.append(
            #{generate_method(len, tl(identifiers), level - 1, type)}
            )
            }\n
            return w#{level}
            }\n
            """
          _ -> "try DER.sequence(root, identifier: .sequence, rootNode: nodes)"
        end
        # dd =
        end
    end

    def variable_type(level, type) do
        IO.inspect(type)
      String.duplicate("[",  level) <> type <> String.duplicate("]", level)
    end

    defp generate_serialize_code(variable_names) do
      serialize_body = generate_serialize_body(tl(variable_names), "codec1", "element")

      """
      @inlinable func serialize(into coder: inout DER.Serializer,
          withIdentifier identifier: ASN1Identifier) throws {
          try coder.appendConstructedNode(identifier: identifier) {coder_ in
          try coder_.appendConstructedNode(identifier: #{hd(variable_names)}) {
           codec1 in for element in w {
              #{serialize_body}
          }}
          }
      }
      """
    end

    defp generate_serialize_body([current | rest], variable_name, element) do
      next_variable_name = "#{variable_name}_1"
      next_element = "#{element}_1"
      """
      try #{variable_name}.appendConstructedNode(identifier: #{current}) {
      #{next_variable_name} in for #{next_element} in #{element} {
              #{generate_serialize_body(rest, next_variable_name, next_element)}
          }
      }
      """
    end

    defp generate_serialize_body([], variable_name, element) do
      """
      try #{variable_name}.serializeSequenceOf(#{element})
      """
    end
end



defmodule ASN1 do
  def get_sequence_and_set_of({:type, _, inner_type, _, _, _} = node, acc) do
      case inner_type do
        {:"SEQUENCE OF", res } -> get_sequence_and_set_of(res, [".sequence" | acc])
        {:"SET OF",res } -> get_sequence_and_set_of(res , [".set" | acc])
        _ -> {acc, inner_type}
    end
  end




  def print(format, params) do
      case :application.get_env(:asn1scg, "save", true) and :application.get_env(:asn1scg, "verbose", false) do
           true -> :io.format(format, params)
              _ -> []
      end
  end

  def array(name,type,tag,level \\ "") when tag == :sequence or tag == :set do
      name1 = bin(normalizeName(name))
      type1 = bin(type)
      case level do
           "" -> []
            _ -> print ~c'array: #{level} : ~ts = [~ts] ~p ~n', [name1, type1, tag]
      end
     :io.format ~c'seqof:8: ~p [~ts]~n', [name1, lookup(bin(type1)) ]
      setEnv(name1, "[#{type1}]")
      setEnv({:array, name1}, {tag, type1})
      name1
  end

  def fieldName({:contentType, {:Externaltypereference,_,_mod, name}}), do: normalizeName("#{name}")
  def fieldName(name), do: normalizeName("#{name}")

  def fieldType(name,field,{:ComponentType,_,_,{:type,_,oc,_,[],:no},_opt,_,_}), do: fieldType(name, field, oc)
  def fieldType(name,field,{:"SEQUENCE", _, _, _, _}), do: bin(name) <> "_" <> bin(field) <> "_Sequence"
  def fieldType(name,field,{:"CHOICE",_}), do: bin(name) <> "_" <> bin(field) <> "_Choice"
  def fieldType(name,field,{:"ENUMERATED",_}), do: bin(name) <> "_" <> bin(field) <> "_Enum"
  def fieldType(name,field,{:"INTEGER",_}), do: bin(name) <> "_" <> bin(field) <> "_IntEnum"
  def fieldType(name,field,{:"SEQUENCE OF", type}) do bin = "[#{sequenceOf(name,field,type)}]" ; array("#{bin}", partArray(bin), :sequence, "pro #{name}.#{field}")  end
  def fieldType(name,field,{:"SET OF", type}) do bin = "[#{sequenceOf(name,field,type)}]" ; array("#{bin}", partArray(bin), :set, "pro #{name}.#{field}")  end
  def fieldType(_,_,{:contentType, {:Externaltypereference,_,_,type}}), do: "#{type}"
  def fieldType(_,_,{:"BIT STRING", _}), do: "ASN1BitString"
  def fieldType(_,_,{:pt, {_,_,_,type}, _}) when is_atom(type), do: "#{type}"
  def fieldType(_,_,{:ANY_DEFINED_BY, type}) when is_atom(type), do: "ASN1Any"
  def fieldType(name,field,{:Externaltypereference,_,_,type}) when type == :OrganizationalUnitNames do
     :io.format ~c'seqof:1: ~p.~p ~ts~n', [name, field, type ] #lookup(bin(type)) ]
      "#{substituteType(lookup(bin(type)))}"
  end
  def fieldType(_name,_field,{:Externaltypereference,_,_,type}) do
#      :io.format 'seqof:2: ~p.~p ~ts~n', [name, field, :io_lib.format('~p',[type]) ]
       "#{substituteType(lookup(bin(type)))}"
  end
  def fieldType(_,_,{:ObjectClassFieldType,_,_,[{_,type}],_}), do: "#{type}"
  def fieldType(_,_,type) when is_atom(type), do: "#{type}"
  def fieldType(name,_,_), do: "#{name}"

  def sequenceOf(name,field,type) do
#      :io.format 'seqof:3: ~p.~p~n', [name, field]
      sequenceOf2(name,field,type)
  end

  def sequenceOf2(name,field,{:type,_,{:Externaltypereference,_,_,type},_,_,_}), do: "#{sequenceOf(name,field,type)}"
  def sequenceOf2(name,field,{:type,_,{:"SET OF", type},_,_,_}) do bin = "[#{sequenceOf(name,field,type)}]" ; array("#{bin}", partArray(bin), :set, "arr #{name}.#{field}")  end
  def sequenceOf2(name,field,{:type,_,{:"SEQUENCE OF", type},_,_,_}) do bin = "[#{sequenceOf(name,field,type)}]" ; array("#{bin}", partArray(bin), :sequence, "arr #{name}.#{field}") end
  def sequenceOf2(name,field,{:type,_,{:CHOICE, cases} = sum,_,_,_}) do
      choice(fieldType(name,field,sum), cases, [], true) ; bin(name) <> "_" <> bin(field) <> "_Choice" end
  def sequenceOf2(name,field,{:type,_,{:SEQUENCE, _, _, _, fields} = product,_,_,_}) do
      sequence(fieldType(name,field,product), fields, [], true) ; bin(name) <> "_" <> bin(field) <> "_Sequence" end
  def sequenceOf2(name,field,{:type,_,type,_,_,_}) do "#{sequenceOf(name,field,type)}" end
  def sequenceOf2(name,_,{:Externaltypereference, _, _, type}) do
#      :io.format 'seqof:4: ~p.~p~n', [name, type]
      :application.get_env(:asn1scg, bin(name), bin(type)) end
  def sequenceOf2(_,_,x) when is_tuple(x), do: substituteType("#{bin(:erlang.element(1, x))}")
  def sequenceOf2(_,_,x) when is_atom(x), do: substituteType("#{lookup(x)}")
  def sequenceOf2(_,_,x) when is_binary(x), do: substituteType("#{lookup(x)}")

  def substituteType("TeletexString"),     do: "ASN1TeletexString"
  def substituteType("UniversalString"),   do: "ASN1UniversalString"
  def substituteType("IA5String"),         do: "ASN1IA5String"
  def substituteType("UTF8String"),        do: "ASN1UTF8String"
  def substituteType("PrintableString"),   do: "ASN1PrintableString"
  def substituteType("NumericString"),     do: "ASN1PrintableString"
  def substituteType("BMPString"),         do: "ASN1BMPString"
  def substituteType("INTEGER"),           do: "ArraySlice<UInt8>"
  def substituteType("OCTET STRING"),      do: "ASN1OctetString"
  def substituteType("BIT STRING"),        do: "ASN1BitString"
  def substituteType("OBJECT IDENTIFIER"), do: "ASN1ObjectIdentifier"
  def substituteType("BOOLEAN"),           do: "Bool"
  def substituteType("pt"),                do: "ASN1Any"
  def substituteType("ANY"),               do: "ASN1Any"
  def substituteType("NULL"),              do: "ASN1Null"
  def substituteType("URI"),               do: "ASN1OctetString"
  def substituteType(t),                   do: t

  def emitImprint(), do: "// Generated by ASN1.ERP.UNO Compiler, Copyright © 2023 Namdak Tonpa."
  def emitArg(name), do: "#{name}: #{name}"
  def emitCtorBodyElement(name), do: "self.#{name} = #{name}"
  def emitCtorParam(name, type, opt \\ ""), do: "#{name}: #{normalizeName(type)}#{opt}"
  def emitCtor(params,fields), do: pad(4) <> "@inlinable init(#{params}) {\n#{fields}\n    }\n"
  def emitEnumElement(type, field, value), do: pad(4) <> "static let #{field} = #{type}(rawValue: #{value})\n"
  def emitIntegerEnumElement(field, value), do: pad(4) <> "public static let #{field} = Self(rawValue: #{value})\n"
  def emitOptional(:OPTIONAL, name, body), do: "if let #{name} = self.#{name} { #{body} }"
  def emitOptional(_, _, body), do: "#{body}"
  def emitSequenceElementOptional(name, type, opt \\ ""), do: "@usableFromInline var #{name}: #{lookup(normalizeName(type))}#{opt}\n"

  # Vector Decoder

  def emitSequenceDecoderBodyElement(:OPTIONAL, plicit, no, name, type) when plicit == "Implicit", do:
      "let #{name}: #{type}? = try DER.optionalImplicitlyTagged(&nodes, tag: ASN1Identifier(tagWithNumber: #{no}, tagClass: .contextSpecific))"
  def emitSequenceDecoderBodyElement(:OPTIONAL, plicit, no, name, type) when plicit == "Explicit", do:
      "let #{name}: #{type}? = try DER.optionalExplicitlyTagged(&nodes, tagNumber: #{no}, tagClass: .contextSpecific) { node in return try #{type}(derEncoded: node) }"
  def emitSequenceDecoderBodyElement(_, plicit, no, name, type) when plicit == "Explicit", do:
      "let #{name}: #{type} = try DER.explicitlyTagged(&nodes, tagNumber: #{no}, tagClass: .contextSpecific) { node in return try #{type}(derEncoded: node) }"
  def emitSequenceDecoderBodyElement(_, plicit, no, name, type) when plicit == "Implicit", do:
      "let #{name}: #{type} = (try DER.optionalImplicitlyTagged(&nodes, tag: ASN1Identifier(tagWithNumber: #{no}, tagClass: .contextSpecific)))!"
  def emitSequenceDecoderBodyElement(optional, _, _, name, type), do:
      "let #{name}: #{type}#{opt(optional)} = try #{type}(derEncoded: &nodes)"

  def emitSequenceDecoderBodyElementArray(:OPTIONAL, plicit, no, name, type, spec) when plicit == "Explicit" and no != [] and (spec == "set" or spec == "sequence"), do:
      "let #{name}: [#{type}]? = try DER.optionalExplicitlyTagged(&nodes, tagNumber: #{no}, tagClass: .contextSpecific) { node in try DER.#{spec}(of: #{type}.self, identifier: .#{spec}, rootNode: node) }"
  def emitSequenceDecoderBodyElementArray(_, plicit, no, name, type, spec) when plicit == "Implicit" and no != [] and (spec == "set" or spec == "sequence"), do:
      "let #{name}: [#{type}] = try DER.#{spec}(of: #{type}.self, identifier: ASN1Identifier(tagWithNumber: #{no}, tagClass: .contextSpecific), nodes: &nodes)"
  def emitSequenceDecoderBodyElementArray(_, _, no, name, type, spec) when no != [] and (spec == "set" or spec == "sequence"), do:
      "let #{name}: [#{type}] = try DER.explicitlyTagged(&nodes, tagNumber: #{no}, tagClass: .contextSpecific) { node in try DER.#{spec}(of: #{type}.self, identifier: .#{spec}, rootNode: node) }"
  def emitSequenceDecoderBodyElementArray(optional, _, no, name, type, spec) when no == [], do:
      "let #{name}: [#{type}]#{opt(optional)} = try DER.#{spec}(of: #{type}.self, identifier: .#{spec}, nodes: &nodes)"
  def emitSequenceDecoderBodyElementIntEnum(name, type), do:
      "let #{name} = try #{type}(rawValue: Int(derEncoded: &nodes))"

  # Vector Encoder

  def emitSequenceEncoderBodyElement(_, plicit, no, name, s) when plicit == "Explicit" and no != [] and (s == "set" or s == "sequence"), do:
      "try coder.serialize(explicitlyTaggedWithTagNumber: #{no}, tagClass: .contextSpecific) { codec in try codec.serialize#{spec(s)}(#{name}) }"
  def emitSequenceEncoderBodyElement(_, plicit, no, name, s) when plicit == "Implicit" and no != [] and (s == "set" or s == "sequence"), do:
      "try coder.serialize#{spec(s)}(#{name}, identifier: ASN1Identifier(tagWithNumber: #{no}, tagClass: .contextSpecific))"
  def emitSequenceEncoderBodyElement(_, plicit, no, name, _) when no != [] and plicit == "Implicit", do:
      "try coder.serializeOptionalImplicitlyTagged(#{name}, withIdentifier: ASN1Identifier(tagWithNumber: #{no}, tagClass: .contextSpecific))"
  def emitSequenceEncoderBodyElement(_, plicit, no, name, _) when no != [] and plicit == "Explicit", do:
      "try coder.serialize(explicitlyTaggedWithTagNumber: #{no}, tagClass: .contextSpecific) { codec in try codec.serialize(#{name}) }"
  def emitSequenceEncoderBodyElement(_, _, no, name, spec) when spec == "sequence" and no == [], do:
      "try coder.serializeSequenceOf(#{name})"
  def emitSequenceEncoderBodyElement(_, _, no, name, spec) when spec == "set" and no == [], do:
      "try coder.serializeSetOf(#{name})"
  def emitSequenceEncoderBodyElement(_, _, no, name, _) when no == [], do:
      "try coder.serialize(#{name})"
  def emitSequenceEncoderBodyElementIntEnum(no, name) when no == [], do:
      "try coder.serialize(#{name}.rawValue)"
  def emitSequenceEncoderBodyElementIntEnum(no, name), do:
      "try coder.serialize(#{name}.rawValue, explicitlyTaggedWithTagNumber: #{no}, tagClass: .contextSpecific)"

  # Scalar Sum Component

  def emitChoiceElement(name, type), do: "case #{name}(#{lookup(bin(normalizeName(type)))})\n"
  def emitChoiceEncoderBodyElement(w, no, name, spec) when no == [], do:
      pad(w) <> "case .#{name}(let #{name}): try coder.serialize#{spec}(#{name})"
  def emitChoiceEncoderBodyElement(w, no, name, spec), do:
      pad(w) <> "case .#{name}(let #{name}):\n" <>
      pad(w+4) <> "try coder.appendConstructedNode(\n" <>
      pad(w+4) <> "identifier: ASN1Identifier(tagWithNumber: #{no}, tagClass: .contextSpecific),\n" <>
      pad(w+4) <> "{ coder in try coder.serialize#{spec}(#{name}) })"
  def emitChoiceDecoderBodyElement(w, no, name, type) when no == [], do:
      pad(w) <> "case #{type}.defaultIdentifier:\n" <>
      pad(w+4) <> "self = .#{name}(try #{type}(derEncoded: rootNode))"
  def emitChoiceDecoderBodyElement(w, no, name, type), do:
      pad(w) <> "case ASN1Identifier(tagWithNumber: #{no}, tagClass: .contextSpecific):\n" <>
      pad(w+4) <> "self = .#{name}(try #{type}(derEncoded: rootNode))"

  # Vector Sum Component

  def emitChoiceDecoderBodyElementForArray(w, no, name, type, spec) when no == [], do:
      pad(w) <> "case ASN1Identifier.#{spec}:\n" <>
      pad(w+4) <> "self = .#{name}(try DER.#{spec}(of: #{type}.self, identifier: .#{spec}, rootNode: rootNode))"
  def emitChoiceDecoderBodyElementForArray(w, no,  name, type, spec) when spec == "", do:
      pad(w) <> "case ASN1Identifier(tagWithNumber: #{no}, tagClass: .contextSpecific):\n" <>
      pad(w+4) <> "self = .#{name}(try DER.#{spec}(of: #{type}.self, identifier: .#{spec}, nodes: &nodes))"
  def emitChoiceDecoderBodyElementForArray(w, no,  name, type, spec), do:
      pad(w) <> "case ASN1Identifier(tagWithNumber: #{no}, tagClass: .contextSpecific):\n" <>
      pad(w+4) <> "self = .#{name}(try DER.#{spec}(of: #{type}.self, identifier: .#{spec}, rootNode: rootNode))"

  def emitSequenceDefinition(name,fields,ctor,decoder,encoder, kek), do:
"""
#{emitImprint()}
import SwiftASN1\nimport Crypto\nimport Foundation\n
@usableFromInline struct #{name}: DERImplicitlyTaggable, Hashable, Sendable {
    @inlinable static var defaultIdentifier: ASN1Identifier { .sequence }\n#{fields}#{ctor}
     #{kek};\n
     }
"""

  def emitSetDefinition(name,fields,ctor,decoder,encoder), do:
"""
#{emitImprint()}
import SwiftASN1\nimport Crypto\nimport Foundation\n
@usableFromInline struct #{name}: DERImplicitlyTaggable, Hashable, Sendable {
    @inlinable static var defaultIdentifier: ASN1Identifier { .set }\n#{fields}#{ctor}#{decoder}#{encoder}}
"""

  def emitChoiceDefinition(name,cases,decoder,encoder), do:
"""
#{emitImprint()}
import SwiftASN1\nimport Crypto\nimport Foundation\n
@usableFromInline indirect enum #{name}: DERParseable, DERSerializable, Hashable, Sendable {
#{cases}#{decoder}#{encoder}
}
"""

  def emitEnumerationDefinition(name,cases), do:
"""
#{emitImprint()}
import SwiftASN1\nimport Crypto\nimport Foundation\n
public struct #{name}: DERImplicitlyTaggable, Hashable, Sendable, RawRepresentable {
    public static var defaultIdentifier: ASN1Identifier { .enumerated }
    public var rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public init(derEncoded rootNode: ASN1Node, withIdentifier identifier: ASN1Identifier) throws {
        self.rawValue = try .init(derEncoded: rootNode, withIdentifier: identifier)
    }
    public func serialize(into coder: inout DER.Serializer, withIdentifier identifier: ASN1Identifier) throws {
        try self.rawValue.serialize(into: &coder, withIdentifier: identifier)
    }
#{cases}}
"""

  def emitIntegerEnumDefinition(name,cases), do:
"""
#{emitImprint()}
public struct #{name} : Hashable, Sendable, Comparable {
    @usableFromInline  var rawValue: Int
    @inlinable public static func < (lhs: #{name}, rhs: #{name}) -> Bool { lhs.rawValue < rhs.rawValue }
    @inlinable init(rawValue: Int) { self.rawValue = rawValue }
#{cases}}
"""

  def emitChoiceDecoder(cases), do:
"""
    @inlinable init(derEncoded rootNode: ASN1Node) throws {
        switch rootNode.identifier {\n#{cases}
            default: throw ASN1Error.unexpectedFieldType(rootNode.identifier)
        }
    }
"""

  def emitChoiceEncoder(cases), do:
"""
    @inlinable func serialize(into coder: inout DER.Serializer) throws {
        switch self {\n#{cases}
        }
    }
"""

  def emitSetDecoder(fields, name, args), do:
"""
    @inlinable init(derEncoded root: ASN1Node,
        withIdentifier identifier: ASN1Identifier) throws {
        self = try DER.set(root, identifier: identifier) { nodes in\n#{fields}
            return #{normalizeName(name)}(#{args})
        }
    }
"""

  def emitSequenceDecoder(fields, name, args), do:
"""
    @inlinable init(derEncoded root: ASN1Node,
        withIdentifier identifier: ASN1Identifier) throws {
        self = try DER.sequence(root, identifier: identifier) { nodes in\n#{fields}
            return #{normalizeName(name)}(#{args})
        }
    }
"""

  def emitSequenceEncoder(fields), do:
"""
    @inlinable func serialize(into coder: inout DER.Serializer,
        withIdentifier identifier: ASN1Identifier) throws {
        try coder.appendConstructedNode(identifier: identifier) { coder in\n#{fields}
        }
    }
"""

  def emitIntegerEnums(cases) when is_list(cases) do
      Enum.join(:lists.map(fn
        {:NamedNumber, fieldName, fieldValue} ->
           trace(1)
           emitIntegerEnumElement(fieldName(fieldName), fieldValue)
         _ -> ""
      end, cases), "")
  end

  def emitEnums(name, cases) when is_list(cases) do
      Enum.join(:lists.map(fn
        {:NamedNumber, fieldName, fieldValue} ->
           trace(2)
           emitEnumElement(name, fieldName(fieldName), fieldValue)
         _ -> ""
      end, cases), "")
  end


  def emitCases(name, w, cases, modname) when is_list(cases) do
      Enum.join(:lists.map(fn
        {:ComponentType,_,fieldName,{:type,_,fieldType,_elementSet,[],:no},_optional,_,_} ->
           trace(3)
           field = fieldType(name, fieldName, fieldType)
           case fieldType do
              {:SEQUENCE, _, _, _, fields} ->
                 sequence(fieldType(name,fieldName,fieldType), fields, modname, true)
              {:CHOICE, cases} ->
                 choice(fieldType(name,fieldName,fieldType), cases, modname, true)
              {:INTEGER, cases} ->
                 integerEnum(fieldType(name,fieldName,fieldType), cases, modname, true)
              {:ENUMERATED, cases} ->
                 enumeration(fieldType(name,fieldName,fieldType), cases, modname, true)
              _ ->
                 :skip
           end
           pad(w) <> emitChoiceElement(fieldName(fieldName), substituteType(lookup(field)))
          _ -> ""
      end, cases), "")
  end


  def emitFields(name, w, fields, modname) when is_list(fields) do
      Enum.join(:lists.map(fn
        {:"COMPONENTS OF", {:type, _, {_,_,_,n}, _, _, :no}} ->
           trace(4)
           inclusion = :application.get_env(:asn1scg, {:type,n}, [])
           emitFields(n, w, inclusion, modname)
        {:ComponentType,_,fieldName,{:type,_,fieldType,_elementSet,[],:no},optional,_,_} ->
           trace(5)
           field = fieldType(name, fieldName, fieldType)
           case fieldType do
              {:SEQUENCE, _, _, _, fields} ->
                 sequence(fieldType(name,fieldName,fieldType), fields, modname, true)
              {:CHOICE, cases} ->
                 choice(fieldType(name,fieldName,fieldType), cases, modname, true)
              {:INTEGER, cases} ->
                 integerEnum(fieldType(name,fieldName,fieldType), cases, modname, true)
              {:ENUMERATED, cases} ->
                 enumeration(fieldType(name,fieldName,fieldType), cases, modname, true)
              _ ->
                 :skip
           end
           print ~c'field: ~ts.~ts : ~ts ~n', [name,fieldName(fieldName), substituteType(lookup(field))]
           pad(w) <>
                emitSequenceElementOptional(fieldName(fieldName), substituteType(lookup(field)), opt(optional))
         _ -> ""
      end, fields), "")
  end


  def emitCtorBody(fields), do:
      Enum.join(:lists.map(fn
        {:"COMPONENTS OF", {:type, _, {_,_,_,n}, _, _, :no}} ->
           trace(6)
           inclusion = :application.get_env(:asn1scg, {:type,n}, [])
           emitCtorBody(inclusion)
        {:ComponentType,_,fieldName,{:type,_,_type,_elementSet,[],:no},_optional,_,_} ->
           trace(7)
           pad(8) <> emitCtorBodyElement(fieldName(fieldName))
        _ -> ""
      end, fields), "\n")


  def emitChoiceEncoderBody(name,cases), do:
      Enum.join(:lists.map(fn
        {:ComponentType,_,fieldName,{:type,tag,{:"SEQUENCE OF", {_,_,_type,_,_,_}},_,_,_},_,_,_} ->
           trace(8)
           emitChoiceEncoderBodyElement(12, tagNo(tag), fieldName(fieldName), "SequenceOf")
        {:ComponentType,_,fieldName,{:type,tag,{:"SET OF", {_,_,_type,_,_,_}},_,_,_},_,_,_} ->
           trace(9)
           emitChoiceEncoderBodyElement(12, tagNo(tag), fieldName(fieldName), "SetOf")
        {:ComponentType,_,fieldName,{:type,tag,type,_elementSet,[],:no},_optional,_,_} ->
           trace(10)
           case {part(lookup(fieldType(name,fieldName,type)),0,1),
                 :application.get_env(:asn1scg, {:array, lookup(fieldType(name,fieldName(fieldName),type))}, [])} do
                {"[", {:set, _}} -> emitChoiceEncoderBodyElement(12, tagNo(tag), fieldName(fieldName), "SetOf")
                {"[", {:sequence, _}} -> emitChoiceEncoderBodyElement(12, tagNo(tag), fieldName(fieldName), "SequenceOf")
                _ -> emitChoiceEncoderBodyElement(12, tagNo(tag), fieldName(fieldName), "")
           end
         _ -> ""
      end, cases), "\n")

  def emitChoiceDecoderBody(name,cases), do:
      Enum.join(:lists.map(fn
        {:ComponentType,_,fieldName,{:type,tag,{:"SEQUENCE OF", {_,_,type,_,_,_}},_,_,_},_,_,_} ->
           trace(11)
           emitChoiceDecoderBodyElementForArray(12, tagNo(tag), fieldName(fieldName),
               substituteType(lookup(fieldType(name, fieldName(fieldName), type))), "sequence")
        {:ComponentType,_,fieldName,{:type,tag,{:"SET OF", {_,_,type,_,_,_}},_,_,_},_,_,_} ->
           trace(12)
           emitChoiceDecoderBodyElementForArray(12, tagNo(tag), fieldName(fieldName),
               substituteType(lookup(fieldType(name, fieldName(fieldName), type))), "set")
        {:ComponentType,_,fieldName,{:type,tag,type,_elementSet,[],:no},_optional,_,_} ->
           trace(13)
           case {part(lookup(fieldType(name,fieldName,type)),0,1),
                 :application.get_env(:asn1scg, {:array, lookup(fieldType(name,fieldName(fieldName),type))}, [])} do
                {"[", {:set, inner}} -> emitChoiceDecoderBodyElementForArray(12, tagNo(tag), fieldName(fieldName), inner, "set")
                {"[", {:sequence, inner}} -> emitChoiceDecoderBodyElementForArray(12, tagNo(tag), fieldName(fieldName), inner, "sequence")
                _ -> emitChoiceDecoderBodyElement(12, tagNo(tag), fieldName(fieldName),
                        substituteType(lookup(fieldType(name, fieldName(fieldName), type))))
           end
         _ -> ""
      end, cases), "\n")

  def emitSequenceDecoderBody(name,fields), do:
      Enum.join(:lists.map(fn
        {:"COMPONENTS OF", {:type, _, {_,_,_,n}, _, _, :no}} ->
           trace(14)
           inclusion = :application.get_env(:asn1scg, {:type,n}, [])
           emitSequenceDecoderBody(n, inclusion)
        {:ComponentType,_,fieldName,{:type,tag,type,_elementSet,[],:no},optional,_,_} ->
           look = substituteType(normalizeName(lookup(fieldType(name,fieldName,type))))
           res = case type do
                {:"SEQUENCE OF", {:type, _, inner, _, _, _}} ->
                    trace(15)
                    emitSequenceDecoderBodyElementArray(optional, plicit(tag), tagNo(tag), fieldName(fieldName), substituteType(lookup(fieldType(name,fieldName,inner))), "sequence")
                {:"SET OF", {:type, _, inner, _, _, _}} ->
                    trace(16)
                    emitSequenceDecoderBodyElementArray(optional, plicit(tag), tagNo(tag), fieldName(fieldName), substituteType(lookup(fieldType(name,fieldName,inner))), "set")
                {:"INTEGER", _} ->
                    trace(17)
                    emitSequenceDecoderBodyElementIntEnum(fieldName(fieldName), substituteType(lookup(fieldType(name,fieldName(fieldName),type))))
                {:Externaltypereference,_,_,inner} ->
                    trace(18)
                    case :application.get_env(:asn1scg, {:array, bin(inner)}, []) do
                       {:sequence, _} -> emitSequenceDecoderBodyElementArray(optional, plicit(tag), tagNo(tag), fieldName(fieldName), substituteType(part(look,1,:erlang.size(look)-2)), "sequence")
                       {:set, _} -> emitSequenceDecoderBodyElementArray(optional, plicit(tag), tagNo(tag), fieldName(fieldName), substituteType(part(look,1,:erlang.size(look)-2)), "set")
                        _ -> emitSequenceDecoderBodyElement(optional, plicit(tag), tagNo(tag), fieldName(fieldName), look)
                    end
              _ ->  trace(19)
                    emitSequenceDecoderBodyElement(optional, plicit(tag), tagNo(tag), fieldName(fieldName), look)
          end
          pad(12) <> res
         _ -> ""
      end, fields), "\n")

  def emitSequenceEncoderBody(_name, fields), do:
      Enum.join(:lists.map(fn
        {:"COMPONENTS OF", {:type, _, {_,_,_,name}, _, _, :no}} ->
           trace(20)
           inclusion = :application.get_env(:asn1scg, {:type,name}, [])
           emitSequenceEncoderBody(name, inclusion)
        {:ComponentType,_,fieldName,{:type,tag,type,_elementSet,[],:no},optional,_,_} ->
           res = case type do
                {:"SEQUENCE OF", {:type, _, _innerType, _, _, _}} ->
                    trace(21)
                    emitSequenceEncoderBodyElement(optional, plicit(tag), tagNo(tag), fieldName(fieldName), "sequence")
                {:"SET OF", {:type, _, _innerType, _, _, _}} ->
                    trace(22)
                    emitSequenceEncoderBodyElement(optional, plicit(tag), tagNo(tag), fieldName(fieldName), "set")
                {:"INTEGER", _} ->
                    trace(23)
                    emitSequenceEncoderBodyElementIntEnum(tagNo(tag), fieldName(fieldName))
                {:Externaltypereference,_,_,inner} ->
                    trace(24)
                    case :application.get_env(:asn1scg, {:array, bin(inner)}, []) do
                       {:sequence, _} -> emitSequenceEncoderBodyElement(optional, plicit(tag), tagNo(tag), fieldName(fieldName), "sequence")
                       {:set, _} -> emitSequenceEncoderBodyElement(optional, plicit(tag), tagNo(tag), fieldName(fieldName), "set")
                        _ -> emitSequenceEncoderBodyElement(optional, plicit(tag), tagNo(tag), fieldName(fieldName), "")
                    end
              _ ->  trace(25)
                    emitSequenceEncoderBodyElement(optional, plicit(tag), tagNo(tag), fieldName(fieldName), "")
           end
           pad(12) <> emitOptional(optional, fieldName(fieldName), res)
         _ -> ""
      end, fields), "\n")

  def emitParams(name,fields) when is_list(fields) do
      Enum.join(:lists.map(fn
        {:"COMPONENTS OF", {:type, _, {_,_,_,n}, _, _, :no}} ->
           trace(26)
           inclusion = :application.get_env(:asn1scg, {:type,n}, [])
           emitParams(n,inclusion)
        {:ComponentType,_,fieldName,{:type,_,type,_elementSet,[],:no},optional,_,_} ->
           trace(27)
           emitCtorParam(fieldName(fieldName), substituteType(lookup(fieldType(name,fieldName,type))), opt(optional))
         _ -> ""
      end, fields), ", ")
  end

  def emitArgs(fields) when is_list(fields) do
      Enum.join(:lists.map(fn
        {:"COMPONENTS OF", {:type, _, {_,_,_,n}, _, _, :no}} ->
           trace(28)
           inclusion = :application.get_env(:asn1scg, {:type,n}, [])
           emitArgs(inclusion)
        {:ComponentType,_,fieldName,{:type,_,_type,_elementSet,[],:no},_optional,_,_} ->
           trace(29)
           emitArg(fieldName(fieldName))
         _ ->  ""
      end, fields), ", ")
  end

  def dump() do
      :lists.foldl(fn {{:array,x},{tag,y}}, _ -> print ~c'env array: ~ts = [~ts] ~tp ~n', [x,y,tag]
                      {x,y}, _  when is_binary(x) -> print ~c'env alias: ~ts = ~ts ~n', [x,y]
                      {{:type,x},_}, _ -> print ~c'env type: ~ts = ... ~n', [x]
                      _, _ -> :ok
      end, [], :lists.sort(:application.get_all_env(:asn1scg)))
  end

  def compile() do
      {:ok, f} = :file.list_dir inputDir()
      files = :lists.filter(fn x -> [_,y] = :string.tokens(x, ~c'.') ; y == ~c'asn1' end, f)
      setEnv(:save, false) ; :lists.map(fn file -> compile(false, inputDir() <> :erlang.list_to_binary(file))  end, files)
      setEnv(:save, false) ; :lists.map(fn file -> compile(false, inputDir() <> :erlang.list_to_binary(file))  end, files)
      setEnv(:save, true)  ; :lists.map(fn file -> compile(true,  inputDir() <> :erlang.list_to_binary(file))  end, files)
      print ~c'inputDir: ~ts~n', [inputDir()]
      print ~c'outputDir: ~ts~n', [outputDir()]
      print ~c'coverage: ~tp~n', [coverage()]
      dump()
      :ok
  end

  def coverage() do
         :lists.map(fn x -> :application.get_env(:asn1scg,
              {:trace, x}, []) end,:lists.seq(1,30)) end

  def compile(save, file) do
      tokens = :asn1ct_tok.file file
      {:ok, mod} = :asn1ct_parser2.parse file, tokens
      {:module, pos, modname, defid, tagdefault, exports, imports, _, declarations} = mod
      :lists.map(fn
         {:typedef,  _, pos, name, type} -> compileType(pos, name, type, modname, save)
         {:ptypedef, _, pos, name, args, type} -> compilePType(pos, name, args, type)
         {:classdef, _, pos, name, mod, type} -> compileClass(pos, name, mod, type)
         {:valuedef, _, pos, name, type, value, mod} -> compileValue(pos, name, type, value, mod)
      end, declarations)
      compileModule(pos, modname, defid, tagdefault, exports, imports)
  end

  def compileType(_, name, typeDefinition, modname, save \\ true) do
      res = case typeDefinition do
          {:type, _, {:"INTEGER", cases}, _, [], :no} ->  setEnv(name, "Int") ; integerEnum(name, cases, modname, save)
          {:type, _, {:"ENUMERATED", cases}, _, [], :no} -> enumeration(name, cases, modname, save)
          {:type, _, {:"CHOICE", cases}, _, [], :no} -> choice(name, cases, modname, save)
          {:type, _, {:"SEQUENCE", _, _, _, fields}, _, _, :no} -> sequence(name, fields, modname, save)
          {:type, _, {:"SET", _, _, _, fields}, _, _, :no} ->
            :io.format ~c'seqof:548: ~p ~p ~n', [name, name]
            set(name, fields, modname, save)
          {:type, _, {:"SEQUENCE OF", {:type, _, {_, _, _, type}, _, _, _}}, _, _, _} ->
              :io.format ~c'seqof:548: ~p ~p ~n', [name, type]
               array(name,substituteType(lookup(bin(type))),:sequence,"top")
          {:type, [], {:"SEQUENCE OF", {_, _, {_, _, _, _,_type}, _, _, _}}, _, _, _} ->
              :io.format ~c'seqof:536: ~p ~n', [name]
          {:type, [], {:"SEQUENCE OF", {_, _, {_, _, _, _, _,type}, _, _, _}}, _, _, _} ->
              :io.format ~c'seqof:548: ~p ~p ~n', [name, type]
               array(name,substituteType(lookup(bin(type))),:sequence,"top")
          {:type, [], {:"SEQUENCE OF", {_, _, {_,{_,_, type, _},_} , _, _, _}}, _, _, _} ->
              :io.format ~c'seqof:548: ~p ~p ~n', [name, type]
               array(name,substituteType(lookup(bin(type))),:sequence,"top")
          {:type, [], {:"SEQUENCE OF", {_, _, :"OBJECT IDENTIFIER" , _, _, _}}, _, _, _} ->
            :skip
          {:type, _, {:"SET OF", {:type, _, {_, _, _, type}, _, _, _}}, _, _, _} ->
              :io.format ~c'seqof:548: ~p ~p ~n', [name, type]
               array(name,substituteType(lookup(bin(type))),:set,"top")
          {:type, [], {:"SET OF", {_, _, {_, _, _, _, type}, _, _, _}}, _, _, _} ->
              :io.format ~c'seqof:548: ~p ~p ~n', [name, type]
               array(name,substituteType(lookup(bin(type))),:set,"top")
          {:type, [], {:"SET OF", {_, _, {_, {_, _, type, _}, _}, _, _, _}}, _, _, _} ->
            #    array(name,substituteType(lookup(bin(type))),:set,"top")
              :io.format ~c'seqof:548: ~p ~p ~n', [name, type]
              array(name,substituteType(lookup(bin(type))),:set,"top")
            #   exit(1)
          {:type, _, {:"BIT STRING",_}, _, [], :no} -> setEnv(name, "BIT STRING")
          {:type, _, :'BIT STRING', _, [], :no} -> setEnv(name, "BIT STRING")
          {:type, _, :'INTEGER', _set, [], :no} -> setEnv(name, "INTEGER")
          {:type, _, :'NULL', _set, [], :no} -> setEnv(name, "NULL")
          {:type, _, :'ANY', _set, [], :no} -> setEnv(name, "ANY")
          {:type, _, :'PrintableString', _set, [], :no} -> setEnv(name, "PrintableString")
          {:type, _, :'NumericString', _set, [], :no} -> setEnv(name, "PrintableString")
          {:type, _, :'IA5String', _set, [], :no} -> setEnv(name, "IA5String")
          {:type, _, :'TeletexString', _set, [], :no} -> setEnv(name, "TeletexString")
          {:type, _, :'UniversalString', _set, [], :no} -> setEnv(name, "UniversalString")
          {:type, _, :'OBJECT IDENTIFIER', _, _, :no} -> setEnv(name, "OBJECT IDENTIFIER") ; :skip
          {:type, _, :'OCTET STRING', [], [], :no} -> setEnv(name, "OCTET STRING")
          {:type, _, {:Externaltypereference, _, _, ext}, _set, [], _} -> setEnv(name, ext)
          {:type, _, {:pt, _, _}, _, [], _} -> :skip
          {:type, _, {:ObjectClassFieldType, _, _, _, _fields}, _, _, :no} -> :skip
          {:type, _, {:SEQUENCE, _, _, _, _fields}, _, _, :no} -> :skip
          {:Object, _, _val} -> :skip
          {:Object, _, _, _} -> :skip
          {:ObjectSet, _, _, _, _} -> :skip
      end
      case res do
           :skip -> print ~c'Unhandled type definition ~p: ~p~n', [name, typeDefinition]
               _ -> :skip
      end
  end

  def compileValue(_pos, name, type, value, _mod), do: (print ~c'Unhandled value definition ~p : ~p = ~p ~n', [name, type, value] ; [])
  def compileClass(_pos, name, _mod, type), do: (print ~c'Unhandled class definition ~p : ~p~n', [name, type] ; [])
  def compilePType(_pos, name, args, type), do: (print ~c'Unhandled PType definition ~p : ~p(~p)~n', [name, type, args] ; [])
  def compileModule(_pos, _name, _defid, _tagdefault, _exports, _imports), do: []

  def sequence(name, fields, modname, saveFlag) do
      :application.set_env(:asn1scg, {:type,name}, fields)
      res = Enum.at(fields, 0)
      {_, _ , _ ,ff, _, _ , _} = res
      {kek, type } =  get_sequence_and_set_of(ff, [])
      decoder = emitSequenceDecoder(emitSequenceDecoderBody(name, fields), name, emitArgs(fields))
      encoder = emitSequenceEncoder(emitSequenceEncoderBody(name, fields))
      default = "#{decoder} #{encoder}"
      lol =  ASN1SwiftCodeGenerator.generate_swift_code(kek, default, substituteType(lookup(bin(type))))
      save(saveFlag, modname, name, emitSequenceDefinition(normalizeName(name),
          emitFields(name, 4, fields, modname), emitCtor(emitParams(name,fields), emitCtorBody(fields)),
          decoder, encoder, lol))
  end

  def set(name, fields, modname, saveFlag) do
      :application.set_env(:asn1scg, {:type,name}, fields)
      save(saveFlag, modname, name, emitSetDefinition(normalizeName(name),
          emitFields(name, 4, fields, modname), emitCtor(emitParams(name,fields), emitCtorBody(fields)),
          emitSetDecoder(emitSequenceDecoderBody(name, fields), name, emitArgs(fields)),
          emitSequenceEncoder(emitSequenceEncoderBody(name, fields))))
  end

  def choice(name, cases, modname, saveFlag) do
      save(saveFlag, modname, name, emitChoiceDefinition(normalizeName(name),
          emitCases(name, 4, cases, modname),
          emitChoiceDecoder(emitChoiceDecoderBody(name,cases)),
          emitChoiceEncoder(emitChoiceEncoderBody(name,cases))))
  end

  def enumeration(name, cases, modname, saveFlag) do
      save(saveFlag, modname, bin(name),
           emitEnumerationDefinition(normalizeName(name),
           emitEnums(name, cases)))
  end

  def integerEnum(name, cases, modname, saveFlag) do
      save(saveFlag, modname, name,
           emitIntegerEnumDefinition(normalizeName(name),
           emitIntegerEnums(cases)))
  end

  def inputDir(), do: :application.get_env(:asn1scg, "input", "priv/apple/")
  def outputDir(), do: :application.get_env(:asn1scg, "output", "Sources/ASN1SCG/")

  def save(true, _, name, res) do
      dir = outputDir()
      :filelib.ensure_dir(dir)
      norm = normalizeName(bin(name))
      fileName = dir <> norm <> ".swift"
      :ok = :file.write_file(fileName,res)
      verbose = getEnv(:verbose, false) ; setEnv(:verbose, true)
      print ~c'compiled: ~ts.swift~n', [norm] ; setEnv(:verbose, verbose)
  end

  def save(_, _, _, _), do: []

  def lookup(name) do
      b = bin(name)
      case :application.get_env(:asn1scg, b, b) do
           a when a == b -> bin(a)
           x -> lookup(x)
      end
  end

  def plicit([]), do: ""
  def plicit([{:tag,:CONTEXT,_,{:default,:IMPLICIT},_}]), do: "Implicit"
  def plicit([{:tag,:CONTEXT,_,{:default,:EXPLICIT},_}]), do: "Explicit"
  def plicit([{:tag,:CONTEXT,_,:IMPLICIT,_}]), do: "Implicit"
  def plicit([{:tag,:CONTEXT,_,:EXPLICIT,_}]), do: "Explicit"
#   def plicit(_), do: ""

  def opt(:OPTIONAL), do: "?"
  def opt(_), do: ""
  def spec("sequence"), do: "SequenceOf"
  def spec("set"), do: "SetOf"
  def spec(_), do: ""
  def trace(x), do: setEnv({:trace, x}, x)
  def normalizeName(name), do: Enum.join(String.split("#{name}", "-"), "_")
  def setEnv(x,y), do: :application.set_env(:asn1scg, bin(x), y)
  def getEnv(x,y), do: :application.get_env(:asn1scg, bin(x), y)
  def bin(x) when is_atom(x), do: :erlang.atom_to_binary x
  def bin(x) when is_list(x), do: :erlang.list_to_binary x
  def bin(x), do: x
  def tagNo([]), do: []
  def tagNo([{:tag,:CONTEXT,nox,_,_}]) do nox end
  def pad(x), do: String.duplicate(" ", x)
  def partArray(bin), do: part(bin, 1, :erlang.size(bin) - 2)
  def part(a, x, y) do
      case :erlang.size(a) > y - x do
           true -> :binary.part(a, x, y)
              _ -> ""
      end
  end

end

case System.argv() do
  ["compile"]          -> ASN1.compile
  ["compile","-v"]     -> ASN1.setEnv(:verbose, true) ; ASN1.compile
  ["compile",i]        -> ASN1.setEnv(:input, i <> "/") ; ASN1.compile
  ["compile","-v",i]   -> ASN1.setEnv(:input, i <> "/") ; ASN1.setEnv(:verbose, true) ; ASN1.compile
  ["compile",i,o]      -> ASN1.setEnv(:input, i <> "/") ; ASN1.setEnv(:output, o <> "/") ; ASN1.compile
  ["compile","-v",i,o] -> ASN1.setEnv(:input, i <> "/") ; ASN1.setEnv(:output, o <> "/") ; ASN1.setEnv(:verbose, true) ; ASN1.compile
  _ -> :io.format(~c'Copyright © 2023 Namdak Tonpa.~n')
       :io.format(~c'ISO 8824 ITU/IETF X.680-690 ERP/1 ASN.1 DER Compiler, version 0.9.1.~n')
       :io.format(~c'Usage: ./asn1.ex help | compile [-v] [input [output]]~n')
end
