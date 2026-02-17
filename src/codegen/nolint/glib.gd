extends Node

static var v: Lib = Lib.new()


func ToV2(value: GV2) -> Vector2:
	return Vector2(value.get_x(), value.get_y())


func ToV2i(value: GV2i) -> Vector2i:
	return Vector2i(value.get_x(), value.get_y())


func ToV3(value: GV3) -> Vector3:
	return Vector3(value.get_x(), value.get_y(), value.get_z())


func ToV3i(value: GV3i) -> Vector3i:
	return Vector3i(value.get_x(), value.get_y(), value.get_z())


static var _glib_mtime: int = -1

const glib_binary_path: String = "res://assets/glib.binpb"


func _reload_gamelib() -> void:
	_glib_mtime = FileAccess.get_modified_time(glib_binary_path)
	var glib_file = FileAccess.open(glib_binary_path, FileAccess.READ)
	assert(glib_file)
	var glib_bytes: PackedByteArray = glib_file.get_buffer(glib_file.get_length())
	glib_file.close()
	var err = v.from_bytes(glib_bytes)
	assert(not err)


func _ready() -> void:
	_reload_gamelib()
	get_tree().debug_collisions_hint = glib.v.get_debug_collisions() != 0


func _physics_process(_dt: float) -> void:
	if _glib_mtime != FileAccess.get_modified_time(glib_binary_path):
		v = Lib.new()
		_reload_gamelib()

#
# BSD 3-Clause License
#
# Copyright (c) 2018 - 2023, Oleg Malyavkin
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# DEBUG_TAB redefine this "  " if you need, example: const DEBUG_TAB = "\t"

const PROTO_VERSION = 3

const DEBUG_TAB: String = "  "

enum PB_ERR {
	NO_ERRORS = 0,
	VARINT_NOT_FOUND = -1,
	REPEATED_COUNT_NOT_FOUND = -2,
	REPEATED_COUNT_MISMATCH = -3,
	LENGTHDEL_SIZE_NOT_FOUND = -4,
	LENGTHDEL_SIZE_MISMATCH = -5,
	PACKAGE_SIZE_MISMATCH = -6,
	UNDEFINED_STATE = -7,
	PARSE_INCOMPLETE = -8,
	REQUIRED_FIELDS = -9,
}

enum PB_DATA_TYPE {
	INT32 = 0,
	SINT32 = 1,
	UINT32 = 2,
	INT64 = 3,
	SINT64 = 4,
	UINT64 = 5,
	BOOL = 6,
	ENUM = 7,
	FIXED32 = 8,
	SFIXED32 = 9,
	FLOAT = 10,
	FIXED64 = 11,
	SFIXED64 = 12,
	DOUBLE = 13,
	STRING = 14,
	BYTES = 15,
	MESSAGE = 16,
	MAP = 17,
}

const DEFAULT_VALUES_2 = {
	PB_DATA_TYPE.INT32: null,
	PB_DATA_TYPE.SINT32: null,
	PB_DATA_TYPE.UINT32: null,
	PB_DATA_TYPE.INT64: null,
	PB_DATA_TYPE.SINT64: null,
	PB_DATA_TYPE.UINT64: null,
	PB_DATA_TYPE.BOOL: null,
	PB_DATA_TYPE.ENUM: null,
	PB_DATA_TYPE.FIXED32: null,
	PB_DATA_TYPE.SFIXED32: null,
	PB_DATA_TYPE.FLOAT: null,
	PB_DATA_TYPE.FIXED64: null,
	PB_DATA_TYPE.SFIXED64: null,
	PB_DATA_TYPE.DOUBLE: null,
	PB_DATA_TYPE.STRING: null,
	PB_DATA_TYPE.BYTES: null,
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: null,
}

const DEFAULT_VALUES_3 = {
	PB_DATA_TYPE.INT32: 0,
	PB_DATA_TYPE.SINT32: 0,
	PB_DATA_TYPE.UINT32: 0,
	PB_DATA_TYPE.INT64: 0,
	PB_DATA_TYPE.SINT64: 0,
	PB_DATA_TYPE.UINT64: 0,
	PB_DATA_TYPE.BOOL: false,
	PB_DATA_TYPE.ENUM: 0,
	PB_DATA_TYPE.FIXED32: 0,
	PB_DATA_TYPE.SFIXED32: 0,
	PB_DATA_TYPE.FLOAT: 0.0,
	PB_DATA_TYPE.FIXED64: 0,
	PB_DATA_TYPE.SFIXED64: 0,
	PB_DATA_TYPE.DOUBLE: 0.0,
	PB_DATA_TYPE.STRING: "",
	PB_DATA_TYPE.BYTES: [],
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: [],
}

enum PB_TYPE {
	VARINT = 0,
	FIX64 = 1,
	LENGTHDEL = 2,
	STARTGROUP = 3,
	ENDGROUP = 4,
	FIX32 = 5,
	UNDEFINED = 8,
}

enum PB_RULE {
	OPTIONAL = 0,
	REQUIRED = 1,
	REPEATED = 2,
	RESERVED = 3,
}

enum PB_SERVICE_STATE {
	FILLED = 0,
	UNFILLED = 1,
}


class PBField:
	func _init(a_name: String, a_type: int, a_rule: int, a_tag: int, packed: bool, a_value = null):
		name = a_name
		type = a_type
		rule = a_rule
		tag = a_tag
		option_packed = packed
		value = a_value


	var name: String
	var type: int
	var rule: int
	var tag: int
	var option_packed: bool
	var value
	var is_map_field: bool = false
	var option_default: bool = false


class PBTypeTag:
	var ok: bool = false
	var type: int
	var tag: int
	var offset: int


class PBServiceField:
	var field: PBField
	var func_ref = null
	var state: int = PB_SERVICE_STATE.UNFILLED


class PBPacker:
	static func convert_signed(n: int) -> int:
		if n < -2147483648:
			return (n << 1) ^ (n >> 63)
		else:
			return (n << 1) ^ (n >> 31)


	static func deconvert_signed(n: int) -> int:
		if n & 0x01:
			return ~(n >> 1)
		else:
			return (n >> 1)


	static func pack_varint(value) -> PackedByteArray:
		var varint: PackedByteArray = PackedByteArray()
		if typeof(value) == TYPE_BOOL:
			if value:
				value = 1
			else:
				value = 0
		for _i in range(9):
			var b = value & 0x7F
			value >>= 7
			if value:
				varint.append(b | 0x80)
			else:
				varint.append(b)
				break
		if varint.size() == 9 && (varint[8] & 0x80 != 0):
			varint.append(0x01)
		return varint


	static func pack_bytes(value, count: int, data_type: int) -> PackedByteArray:
		var bytes: PackedByteArray = PackedByteArray()
		if data_type == PB_DATA_TYPE.FLOAT:
			var spb: StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_float(value)
			bytes = spb.get_data_array()
		elif data_type == PB_DATA_TYPE.DOUBLE:
			var spb: StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_double(value)
			bytes = spb.get_data_array()
		else:
			for _i in range(count):
				bytes.append(value & 0xFF)
				value >>= 8
		return bytes


	static func unpack_bytes(bytes: PackedByteArray, index: int, count: int, data_type: int):
		var value = 0
		if data_type == PB_DATA_TYPE.FLOAT:
			var spb: StreamPeerBuffer = StreamPeerBuffer.new()
			for i in range(index, count + index):
				spb.put_u8(bytes[i])
			spb.seek(0)
			value = spb.get_float()
		elif data_type == PB_DATA_TYPE.DOUBLE:
			var spb: StreamPeerBuffer = StreamPeerBuffer.new()
			for i in range(index, count + index):
				spb.put_u8(bytes[i])
			spb.seek(0)
			value = spb.get_double()
		else:
			for i in range(index + count - 1, index - 1, -1):
				value |= (bytes[i] & 0xFF)
				if i != index:
					value <<= 8
		return value


	static func unpack_varint(varint_bytes) -> int:
		var value: int = 0
		for i in range(varint_bytes.size() - 1, -1, -1):
			value |= varint_bytes[i] & 0x7F
			if i != 0:
				value <<= 7
		return value


	static func pack_type_tag(type: int, tag: int) -> PackedByteArray:
		return pack_varint((tag << 3) | type)


	static func isolate_varint(bytes: PackedByteArray, index: int) -> PackedByteArray:
		var result: PackedByteArray = PackedByteArray()
		for i in range(index, bytes.size()):
			result.append(bytes[i])
			if !(bytes[i] & 0x80):
				break
		return result


	static func unpack_type_tag(bytes: PackedByteArray, index: int) -> PBTypeTag:
		var varint_bytes: PackedByteArray = isolate_varint(bytes, index)
		var result: PBTypeTag = PBTypeTag.new()
		if varint_bytes.size() != 0:
			result.ok = true
			result.offset = varint_bytes.size()
			var unpacked: int = unpack_varint(varint_bytes)
			result.type = unpacked & 0x07
			result.tag = unpacked >> 3
		return result


	static func pack_length_delimeted(type: int, tag: int, bytes: PackedByteArray) -> PackedByteArray:
		var result: PackedByteArray = pack_type_tag(type, tag)
		result.append_array(pack_varint(bytes.size()))
		result.append_array(bytes)
		return result


	static func pb_type_from_data_type(data_type: int) -> int:
		if data_type == PB_DATA_TYPE.INT32 || data_type == PB_DATA_TYPE.SINT32 || data_type == PB_DATA_TYPE.UINT32 || data_type == PB_DATA_TYPE.INT64 || data_type == PB_DATA_TYPE.SINT64 || data_type == PB_DATA_TYPE.UINT64 || data_type == PB_DATA_TYPE.BOOL || data_type == PB_DATA_TYPE.ENUM:
			return PB_TYPE.VARINT
		elif data_type == PB_DATA_TYPE.FIXED32 || data_type == PB_DATA_TYPE.SFIXED32 || data_type == PB_DATA_TYPE.FLOAT:
			return PB_TYPE.FIX32
		elif data_type == PB_DATA_TYPE.FIXED64 || data_type == PB_DATA_TYPE.SFIXED64 || data_type == PB_DATA_TYPE.DOUBLE:
			return PB_TYPE.FIX64
		elif data_type == PB_DATA_TYPE.STRING || data_type == PB_DATA_TYPE.BYTES || data_type == PB_DATA_TYPE.MESSAGE || data_type == PB_DATA_TYPE.MAP:
			return PB_TYPE.LENGTHDEL
		else:
			return PB_TYPE.UNDEFINED


	static func pack_field(field: PBField) -> PackedByteArray:
		var type: int = pb_type_from_data_type(field.type)
		var type_copy: int = type
		if field.rule == PB_RULE.REPEATED && field.option_packed:
			type = PB_TYPE.LENGTHDEL
		var head: PackedByteArray = pack_type_tag(type, field.tag)
		var data: PackedByteArray = PackedByteArray()
		if type == PB_TYPE.VARINT:
			var value
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						value = convert_signed(v)
					else:
						value = v
					data.append_array(pack_varint(value))
				return data
			else:
				if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
					value = convert_signed(field.value)
				else:
					value = field.value
				data = pack_varint(value)
		elif type == PB_TYPE.FIX32:
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					data.append_array(pack_bytes(v, 4, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 4, field.type))
		elif type == PB_TYPE.FIX64:
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					data.append_array(pack_bytes(v, 8, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 8, field.type))
		elif type == PB_TYPE.LENGTHDEL:
			if field.rule == PB_RULE.REPEATED:
				if type_copy == PB_TYPE.VARINT:
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						var signed_value: int
						for v in field.value:
							signed_value = convert_signed(v)
							data.append_array(pack_varint(signed_value))
					else:
						for v in field.value:
							data.append_array(pack_varint(v))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX32:
					for v in field.value:
						data.append_array(pack_bytes(v, 4, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX64:
					for v in field.value:
						data.append_array(pack_bytes(v, 8, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif field.type == PB_DATA_TYPE.STRING:
					for v in field.value:
						var obj = v.to_utf8_buffer()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
				elif field.type == PB_DATA_TYPE.BYTES:
					for v in field.value:
						data.append_array(pack_length_delimeted(type, field.tag, v))
					return data
				elif typeof(field.value[0]) == TYPE_OBJECT:
					for v in field.value:
						var obj: PackedByteArray = v.to_bytes()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
			else:
				if field.type == PB_DATA_TYPE.STRING:
					var str_bytes: PackedByteArray = field.value.to_utf8_buffer()
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && str_bytes.size() > 0):
						data.append_array(str_bytes)
						return pack_length_delimeted(type, field.tag, data)
				if field.type == PB_DATA_TYPE.BYTES:
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && field.value.size() > 0):
						data.append_array(field.value)
						return pack_length_delimeted(type, field.tag, data)
				elif typeof(field.value) == TYPE_OBJECT:
					var obj: PackedByteArray = field.value.to_bytes()
					if obj.size() > 0:
						data.append_array(obj)
					return pack_length_delimeted(type, field.tag, data)
				else:
					pass
		if data.size() > 0:
			head.append_array(data)
			return head
		else:
			return data


	static func skip_unknown_field(bytes: PackedByteArray, offset: int, type: int) -> int:
		if type == PB_TYPE.VARINT:
			return offset + isolate_varint(bytes, offset).size()
		if type == PB_TYPE.FIX64:
			return offset + 8
		if type == PB_TYPE.LENGTHDEL:
			var length_bytes: PackedByteArray = isolate_varint(bytes, offset)
			var length: int = unpack_varint(length_bytes)
			return offset + length_bytes.size() + length
		if type == PB_TYPE.FIX32:
			return offset + 4
		return PB_ERR.UNDEFINED_STATE


	static func unpack_field(bytes: PackedByteArray, offset: int, field: PBField, type: int, message_func_ref) -> int:
		if field.rule == PB_RULE.REPEATED && type != PB_TYPE.LENGTHDEL && field.option_packed:
			var count = isolate_varint(bytes, offset)
			if count.size() > 0:
				offset += count.size()
				count = unpack_varint(count)
				if type == PB_TYPE.VARINT:
					var val
					var counter = offset + count
					while offset < counter:
						val = isolate_varint(bytes, offset)
						if val.size() > 0:
							offset += val.size()
							val = unpack_varint(val)
							if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
								val = deconvert_signed(val)
							elif field.type == PB_DATA_TYPE.BOOL:
								if val:
									val = true
								else:
									val = false
							field.value.append(val)
						else:
							return PB_ERR.REPEATED_COUNT_MISMATCH
					return offset
				elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
					var type_size
					if type == PB_TYPE.FIX32:
						type_size = 4
					else:
						type_size = 8
					var val
					var counter = offset + count
					while offset < counter:
						if (offset + type_size) > bytes.size():
							return PB_ERR.REPEATED_COUNT_MISMATCH
						val = unpack_bytes(bytes, offset, type_size, field.type)
						offset += type_size
						field.value.append(val)
					return offset
			else:
				return PB_ERR.REPEATED_COUNT_NOT_FOUND
		else:
			if type == PB_TYPE.VARINT:
				var val = isolate_varint(bytes, offset)
				if val.size() > 0:
					offset += val.size()
					val = unpack_varint(val)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						val = deconvert_signed(val)
					elif field.type == PB_DATA_TYPE.BOOL:
						if val:
							val = true
						else:
							val = false
					if field.rule == PB_RULE.REPEATED:
						field.value.append(val)
					else:
						field.value = val
				else:
					return PB_ERR.VARINT_NOT_FOUND
				return offset
			elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
				var type_size
				if type == PB_TYPE.FIX32:
					type_size = 4
				else:
					type_size = 8
				var val
				if (offset + type_size) > bytes.size():
					return PB_ERR.REPEATED_COUNT_MISMATCH
				val = unpack_bytes(bytes, offset, type_size, field.type)
				offset += type_size
				if field.rule == PB_RULE.REPEATED:
					field.value.append(val)
				else:
					field.value = val
				return offset
			elif type == PB_TYPE.LENGTHDEL:
				var inner_size = isolate_varint(bytes, offset)
				if inner_size.size() > 0:
					offset += inner_size.size()
					inner_size = unpack_varint(inner_size)
					if inner_size >= 0:
						if inner_size + offset > bytes.size():
							return PB_ERR.LENGTHDEL_SIZE_MISMATCH
						if message_func_ref != null:
							var message = message_func_ref.call()
							if inner_size > 0:
								var sub_offset = message.from_bytes(bytes, offset, inner_size + offset)
								if sub_offset > 0:
									if sub_offset - offset >= inner_size:
										offset = sub_offset
										return offset
									else:
										return PB_ERR.LENGTHDEL_SIZE_MISMATCH
								return sub_offset
							else:
								return offset
						elif field.type == PB_DATA_TYPE.STRING:
							var str_bytes: PackedByteArray = PackedByteArray()
							for i in range(offset, inner_size + offset):
								str_bytes.append(bytes[i])
							if field.rule == PB_RULE.REPEATED:
								field.value.append(str_bytes.get_string_from_utf8())
							else:
								field.value = str_bytes.get_string_from_utf8()
							return offset + inner_size
						elif field.type == PB_DATA_TYPE.BYTES:
							var val_bytes: PackedByteArray = PackedByteArray()
							for i in range(offset, inner_size + offset):
								val_bytes.append(bytes[i])
							if field.rule == PB_RULE.REPEATED:
								field.value.append(val_bytes)
							else:
								field.value = val_bytes
							return offset + inner_size
					else:
						return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
				else:
					return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
		return PB_ERR.UNDEFINED_STATE


	static func unpack_message(data, bytes: PackedByteArray, offset: int, limit: int) -> int:
		while true:
			var tt: PBTypeTag = unpack_type_tag(bytes, offset)
			if tt.ok:
				offset += tt.offset
				if data.has(tt.tag):
					var service: PBServiceField = data[tt.tag]
					var type: int = pb_type_from_data_type(service.field.type)
					if type == tt.type || (tt.type == PB_TYPE.LENGTHDEL && service.field.rule == PB_RULE.REPEATED && service.field.option_packed):
						var res: int = unpack_field(bytes, offset, service.field, type, service.func_ref)
						if res > 0:
							service.state = PB_SERVICE_STATE.FILLED
							offset = res
							if offset == limit:
								return offset
							elif offset > limit:
								return PB_ERR.PACKAGE_SIZE_MISMATCH
						elif res < 0:
							return res
						else:
							break
				else:
					var res: int = skip_unknown_field(bytes, offset, tt.type)
					if res > 0:
						offset = res
						if offset == limit:
							return offset
						elif offset > limit:
							return PB_ERR.PACKAGE_SIZE_MISMATCH
					elif res < 0:
						return res
					else:
						break
			else:
				return offset
		return PB_ERR.UNDEFINED_STATE


	static func pack_message(data) -> PackedByteArray:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result: PackedByteArray = PackedByteArray()
		var keys: Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED \
				&& !data[i].field.is_map_field \
				&& typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) \
				&& data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result.append_array(pack_field(data[i].field))
			elif data[i].field.rule == PB_RULE.REQUIRED:
				print("Error: required field is not filled: Tag:", data[i].field.tag)
				return PackedByteArray()
		return result


	static func check_required(data) -> bool:
		var keys: Array = data.keys()
		for i in keys:
			if data[i].field.rule == PB_RULE.REQUIRED && data[i].state == PB_SERVICE_STATE.UNFILLED:
				return false
		return true


	static func construct_map(key_values):
		var result = { }
		for kv in key_values:
			result[kv.get_key()] = kv.get_value()
		return result


	static func tabulate(text: String, nesting: int) -> String:
		var tab: String = ""
		for _i in range(nesting):
			tab += DEBUG_TAB
		return tab + text


	static func value_to_string(value, field: PBField, nesting: int) -> String:
		var result: String = ""
		var text: String
		if field.type == PB_DATA_TYPE.MESSAGE:
			result += "{"
			nesting += 1
			text = message_to_string(value.data, nesting)
			if text != "":
				result += "\n" + text
				nesting -= 1
				result += tabulate("}", nesting)
			else:
				nesting -= 1
				result += "}"
		elif field.type == PB_DATA_TYPE.BYTES:
			result += "<"
			for i in range(value.size()):
				result += str(value[i])
				if i != (value.size() - 1):
					result += ", "
			result += ">"
		elif field.type == PB_DATA_TYPE.STRING:
			result += "\"" + value + "\""
		elif field.type == PB_DATA_TYPE.ENUM:
			result += "ENUM::" + str(value)
		else:
			result += str(value)
		return result


	static func field_to_string(field: PBField, nesting: int) -> String:
		var result: String = tabulate(field.name + ": ", nesting)
		if field.type == PB_DATA_TYPE.MAP:
			if field.value.size() > 0:
				result += "(\n"
				nesting += 1
				for i in range(field.value.size()):
					var local_key_value = field.value[i].data[1].field
					result += tabulate(value_to_string(local_key_value.value, local_key_value, nesting), nesting) + ": "
					local_key_value = field.value[i].data[2].field
					result += value_to_string(local_key_value.value, local_key_value, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate(")", nesting)
			else:
				result += "()"
		elif field.rule == PB_RULE.REPEATED:
			if field.value.size() > 0:
				result += "[\n"
				nesting += 1
				for i in range(field.value.size()):
					result += tabulate(str(i) + ": ", nesting)
					result += value_to_string(field.value[i], field, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate("]", nesting)
			else:
				result += "[]"
		else:
			result += value_to_string(field.value, field, nesting)
		result += ";\n"
		return result


	static func message_to_string(data, nesting: int = 0) -> String:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result: String = ""
		var keys: Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED \
				&& !data[i].field.is_map_field \
				&& typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) \
				&& data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result += field_to_string(data[i].field, nesting)
			elif data[i].field.rule == PB_RULE.REQUIRED:
				result += data[i].field.name + ": " + "error"
		return result

############### USER DATA BEGIN ################


class GV2i:
	func _init():
		var service

		__x = PBField.new("x", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __x
		data[__x.tag] = service

		__y = PBField.new("y", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __y
		data[__y.tag] = service


	var data = { }

	var __x: PBField


	func has_x() -> bool:
		if __x.value != null:
			return true
		return false


	func get_x() -> int:
		return __x.value


	func clear_x() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_x(value: int) -> void:
		__x.value = value


	var __y: PBField


	func has_y() -> bool:
		if __y.value != null:
			return true
		return false


	func get_y() -> int:
		return __y.value


	func clear_y() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__y.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_y(value: int) -> void:
		__y.value = value


	func _to_string() -> String:
		return PBPacker.message_to_string(data)


	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)


	func from_bytes(bytes: PackedByteArray, offset: int = 0, limit: int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result


class GV2:
	func _init():
		var service

		__x = PBField.new("x", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __x
		data[__x.tag] = service

		__y = PBField.new("y", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __y
		data[__y.tag] = service


	var data = { }

	var __x: PBField


	func has_x() -> bool:
		if __x.value != null:
			return true
		return false


	func get_x() -> float:
		return __x.value


	func clear_x() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_x(value: float) -> void:
		__x.value = value


	var __y: PBField


	func has_y() -> bool:
		if __y.value != null:
			return true
		return false


	func get_y() -> float:
		return __y.value


	func clear_y() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__y.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_y(value: float) -> void:
		__y.value = value


	func _to_string() -> String:
		return PBPacker.message_to_string(data)


	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)


	func from_bytes(bytes: PackedByteArray, offset: int = 0, limit: int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result


class GV3i:
	func _init():
		var service

		__x = PBField.new("x", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __x
		data[__x.tag] = service

		__y = PBField.new("y", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __y
		data[__y.tag] = service

		__z = PBField.new("z", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __z
		data[__z.tag] = service


	var data = { }

	var __x: PBField


	func has_x() -> bool:
		if __x.value != null:
			return true
		return false


	func get_x() -> int:
		return __x.value


	func clear_x() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_x(value: int) -> void:
		__x.value = value


	var __y: PBField


	func has_y() -> bool:
		if __y.value != null:
			return true
		return false


	func get_y() -> int:
		return __y.value


	func clear_y() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__y.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_y(value: int) -> void:
		__y.value = value


	var __z: PBField


	func has_z() -> bool:
		if __z.value != null:
			return true
		return false


	func get_z() -> int:
		return __z.value


	func clear_z() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__z.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_z(value: int) -> void:
		__z.value = value


	func _to_string() -> String:
		return PBPacker.message_to_string(data)


	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)


	func from_bytes(bytes: PackedByteArray, offset: int = 0, limit: int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result


class GV3:
	func _init():
		var service

		__x = PBField.new("x", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __x
		data[__x.tag] = service

		__y = PBField.new("y", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __y
		data[__y.tag] = service

		__z = PBField.new("z", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __z
		data[__z.tag] = service


	var data = { }

	var __x: PBField


	func has_x() -> bool:
		if __x.value != null:
			return true
		return false


	func get_x() -> float:
		return __x.value


	func clear_x() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_x(value: float) -> void:
		__x.value = value


	var __y: PBField


	func has_y() -> bool:
		if __y.value != null:
			return true
		return false


	func get_y() -> float:
		return __y.value


	func clear_y() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__y.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_y(value: float) -> void:
		__y.value = value


	var __z: PBField


	func has_z() -> bool:
		if __z.value != null:
			return true
		return false


	func get_z() -> float:
		return __z.value


	func clear_z() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__z.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_z(value: float) -> void:
		__z.value = value


	func _to_string() -> String:
		return PBPacker.message_to_string(data)


	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)


	func from_bytes(bytes: PackedByteArray, offset: int = 0, limit: int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result


class GMobToSpawn:
	func _init():
		var service

		__creature_type = PBField.new("creature_type", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __creature_type
		data[__creature_type.tag] = service

		__pos = PBField.new("pos", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __pos
		service.func_ref = Callable(self, "new_pos")
		data[__pos.tag] = service


	var data = { }

	var __creature_type: PBField


	func has_creature_type() -> bool:
		if __creature_type.value != null:
			return true
		return false


	func get_creature_type() -> int:
		return __creature_type.value


	func clear_creature_type() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__creature_type.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_creature_type(value: int) -> void:
		__creature_type.value = value


	var __pos: PBField


	func has_pos() -> bool:
		if __pos.value != null:
			return true
		return false


	func get_pos() -> GV2:
		return __pos.value


	func clear_pos() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__pos.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]


	func new_pos() -> GV2:
		__pos.value = GV2.new()
		return __pos.value


	func _to_string() -> String:
		return PBPacker.message_to_string(data)


	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)


	func from_bytes(bytes: PackedByteArray, offset: int = 0, limit: int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result


class GDoor:
	func _init():
		var service

		__center_pos = PBField.new("center_pos", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __center_pos
		service.func_ref = Callable(self, "new_center_pos")
		data[__center_pos.tag] = service

		__size = PBField.new("size", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __size
		service.func_ref = Callable(self, "new_size")
		data[__size.tag] = service

		__direction = PBField.new("direction", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __direction
		data[__direction.tag] = service


	var data = { }

	var __center_pos: PBField


	func has_center_pos() -> bool:
		if __center_pos.value != null:
			return true
		return false


	func get_center_pos() -> GV2:
		return __center_pos.value


	func clear_center_pos() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__center_pos.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]


	func new_center_pos() -> GV2:
		__center_pos.value = GV2.new()
		return __center_pos.value


	var __size: PBField


	func has_size() -> bool:
		if __size.value != null:
			return true
		return false


	func get_size() -> GV2:
		return __size.value


	func clear_size() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__size.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]


	func new_size() -> GV2:
		__size.value = GV2.new()
		return __size.value


	var __direction: PBField


	func has_direction() -> bool:
		if __direction.value != null:
			return true
		return false


	func get_direction() -> int:
		return __direction.value


	func clear_direction() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__direction.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_direction(value: int) -> void:
		__direction.value = value


	func _to_string() -> String:
		return PBPacker.message_to_string(data)


	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)


	func from_bytes(bytes: PackedByteArray, offset: int = 0, limit: int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result


class GRoom:
	func _init():
		var service

		var __doors_default: Array[GDoor] = []
		__doors = PBField.new("doors", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 2, true, __doors_default)
		service = PBServiceField.new()
		service.field = __doors
		service.func_ref = Callable(self, "add_doors")
		data[__doors.tag] = service

		__size = PBField.new("size", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __size
		service.func_ref = Callable(self, "new_size")
		data[__size.tag] = service

		var __tiles_default: Array[int] = []
		__tiles = PBField.new("tiles", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 4, true, __tiles_default)
		service = PBServiceField.new()
		service.field = __tiles
		data[__tiles.tag] = service


	var data = { }

	var __doors: PBField


	func get_doors() -> Array[GDoor]:
		return __doors.value


	func clear_doors() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__doors.value.clear()


	func add_doors() -> GDoor:
		var element = GDoor.new()
		__doors.value.append(element)
		return element


	var __size: PBField


	func has_size() -> bool:
		if __size.value != null:
			return true
		return false


	func get_size() -> GV2i:
		return __size.value


	func clear_size() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__size.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]


	func new_size() -> GV2i:
		__size.value = GV2i.new()
		return __size.value


	var __tiles: PBField


	func get_tiles() -> Array[int]:
		return __tiles.value


	func clear_tiles() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__tiles.value.clear()


	func add_tiles(value: int) -> void:
		__tiles.value.append(value)


	func _to_string() -> String:
		return PBPacker.message_to_string(data)


	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)


	func from_bytes(bytes: PackedByteArray, offset: int = 0, limit: int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result


class GProgression:
	func _init():
		var service

		__type = PBField.new("type", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __type
		data[__type.tag] = service

		__debug_name = PBField.new("debug_name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __debug_name
		data[__debug_name.tag] = service

		__pos = PBField.new("pos", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __pos
		service.func_ref = Callable(self, "new_pos")
		data[__pos.tag] = service


	var data = { }

	var __type: PBField


	func has_type() -> bool:
		if __type.value != null:
			return true
		return false


	func get_type() -> int:
		return __type.value


	func clear_type() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__type.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_type(value: int) -> void:
		__type.value = value


	var __debug_name: PBField


	func has_debug_name() -> bool:
		if __debug_name.value != null:
			return true
		return false


	func get_debug_name() -> String:
		return __debug_name.value


	func clear_debug_name() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__debug_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]


	func set_debug_name(value: String) -> void:
		__debug_name.value = value


	var __pos: PBField


	func has_pos() -> bool:
		if __pos.value != null:
			return true
		return false


	func get_pos() -> GV2i:
		return __pos.value


	func clear_pos() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__pos.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]


	func new_pos() -> GV2i:
		__pos.value = GV2i.new()
		return __pos.value


	func _to_string() -> String:
		return PBPacker.message_to_string(data)


	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)


	func from_bytes(bytes: PackedByteArray, offset: int = 0, limit: int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result


class GCreature:
	func _init():
		var service

		__type = PBField.new("type", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __type
		data[__type.tag] = service

		__debug_name = PBField.new("debug_name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __debug_name
		data[__debug_name.tag] = service

		__res = PBField.new("res", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __res
		data[__res.tag] = service

		__creature_type = PBField.new("creature_type", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __creature_type
		data[__creature_type.tag] = service

		__hp = PBField.new("hp", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __hp
		data[__hp.tag] = service

		__speed = PBField.new("speed", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __speed
		data[__speed.tag] = service


	var data = { }

	var __type: PBField


	func has_type() -> bool:
		if __type.value != null:
			return true
		return false


	func get_type() -> int:
		return __type.value


	func clear_type() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__type.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_type(value: int) -> void:
		__type.value = value


	var __debug_name: PBField


	func has_debug_name() -> bool:
		if __debug_name.value != null:
			return true
		return false


	func get_debug_name() -> String:
		return __debug_name.value


	func clear_debug_name() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__debug_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]


	func set_debug_name(value: String) -> void:
		__debug_name.value = value


	var __res: PBField


	func has_res() -> bool:
		if __res.value != null:
			return true
		return false


	func get_res() -> String:
		return __res.value


	func clear_res() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__res.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]


	func set_res(value: String) -> void:
		__res.value = value


	var __creature_type: PBField


	func has_creature_type() -> bool:
		if __creature_type.value != null:
			return true
		return false


	func get_creature_type() -> int:
		return __creature_type.value


	func clear_creature_type() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__creature_type.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_creature_type(value: int) -> void:
		__creature_type.value = value


	var __hp: PBField


	func has_hp() -> bool:
		if __hp.value != null:
			return true
		return false


	func get_hp() -> int:
		return __hp.value


	func clear_hp() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__hp.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_hp(value: int) -> void:
		__hp.value = value


	var __speed: PBField


	func has_speed() -> bool:
		if __speed.value != null:
			return true
		return false


	func get_speed() -> float:
		return __speed.value


	func clear_speed() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__speed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_speed(value: float) -> void:
		__speed.value = value


	func _to_string() -> String:
		return PBPacker.message_to_string(data)


	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)


	func from_bytes(bytes: PackedByteArray, offset: int = 0, limit: int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result


class Lib:
	func _init():
		var service

		__debug_collisions = PBField.new("debug_collisions", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __debug_collisions
		data[__debug_collisions.tag] = service

		var __mobs_to_spawn_default: Array[GMobToSpawn] = []
		__mobs_to_spawn = PBField.new("mobs_to_spawn", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 1, true, __mobs_to_spawn_default)
		service = PBServiceField.new()
		service.field = __mobs_to_spawn
		service.func_ref = Callable(self, "add_mobs_to_spawn")
		data[__mobs_to_spawn.tag] = service

		var __rooms_default: Array[GRoom] = []
		__rooms = PBField.new("rooms", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 2, true, __rooms_default)
		service = PBServiceField.new()
		service.field = __rooms
		service.func_ref = Callable(self, "add_rooms")
		data[__rooms.tag] = service

		__player_speed_holding_scale = PBField.new("player_speed_holding_scale", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __player_speed_holding_scale
		data[__player_speed_holding_scale.tag] = service

		__player_speed_inside_enemies_scale = PBField.new("player_speed_inside_enemies_scale", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 17, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __player_speed_inside_enemies_scale
		data[__player_speed_inside_enemies_scale.tag] = service

		__player_roll_duration_seconds = PBField.new("player_roll_duration_seconds", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 18, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __player_roll_duration_seconds
		data[__player_roll_duration_seconds.tag] = service

		__player_roll_distance = PBField.new("player_roll_distance", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 22, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __player_roll_distance
		data[__player_roll_distance.tag] = service

		__player_roll_pow = PBField.new("player_roll_pow", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 23, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __player_roll_pow
		data[__player_roll_pow.tag] = service

		__player_stamina_charges = PBField.new("player_stamina_charges", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 24, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __player_stamina_charges
		data[__player_stamina_charges.tag] = service

		__player_stamina_regen_seconds = PBField.new("player_stamina_regen_seconds", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 20, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __player_stamina_regen_seconds
		data[__player_stamina_regen_seconds.tag] = service

		__player_holding_stamina_regen_scale = PBField.new("player_holding_stamina_regen_scale", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 21, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __player_holding_stamina_regen_scale
		data[__player_holding_stamina_regen_scale.tag] = service

		__creatures_push_radius = PBField.new("creatures_push_radius", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 15, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __creatures_push_radius
		data[__creatures_push_radius.tag] = service

		__creatures_push_force = PBField.new("creatures_push_force", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 16, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __creatures_push_force
		data[__creatures_push_force.tag] = service

		__arrow_speed_min = PBField.new("arrow_speed_min", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __arrow_speed_min
		data[__arrow_speed_min.tag] = service

		__arrow_speed_max = PBField.new("arrow_speed_max", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __arrow_speed_max
		data[__arrow_speed_max.tag] = service

		__arrow_damage_min = PBField.new("arrow_damage_min", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __arrow_damage_min
		data[__arrow_damage_min.tag] = service

		__arrow_damage_max = PBField.new("arrow_damage_max", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 12, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __arrow_damage_max
		data[__arrow_damage_max.tag] = service

		__shooting_min_seconds = PBField.new("shooting_min_seconds", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 13, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __shooting_min_seconds
		data[__shooting_min_seconds.tag] = service

		__shooting_max_seconds = PBField.new("shooting_max_seconds", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 14, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __shooting_max_seconds
		data[__shooting_max_seconds.tag] = service

		__world_size = PBField.new("world_size", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __world_size
		service.func_ref = Callable(self, "new_world_size")
		data[__world_size.tag] = service

		__progression_size = PBField.new("progression_size", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __progression_size
		service.func_ref = Callable(self, "new_progression_size")
		data[__progression_size.tag] = service

		var __progression_default: Array[GProgression] = []
		__progression = PBField.new("progression", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 7, true, __progression_default)
		service = PBServiceField.new()
		service.field = __progression
		service.func_ref = Callable(self, "add_progression")
		data[__progression.tag] = service

		var __creatures_default: Array[GCreature] = []
		__creatures = PBField.new("creatures", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 8, true, __creatures_default)
		service = PBServiceField.new()
		service.field = __creatures
		service.func_ref = Callable(self, "add_creatures")
		data[__creatures.tag] = service


	var data = { }

	var __debug_collisions: PBField


	func has_debug_collisions() -> bool:
		if __debug_collisions.value != null:
			return true
		return false


	func get_debug_collisions() -> int:
		return __debug_collisions.value


	func clear_debug_collisions() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__debug_collisions.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_debug_collisions(value: int) -> void:
		__debug_collisions.value = value


	var __mobs_to_spawn: PBField


	func get_mobs_to_spawn() -> Array[GMobToSpawn]:
		return __mobs_to_spawn.value


	func clear_mobs_to_spawn() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__mobs_to_spawn.value.clear()


	func add_mobs_to_spawn() -> GMobToSpawn:
		var element = GMobToSpawn.new()
		__mobs_to_spawn.value.append(element)
		return element


	var __rooms: PBField


	func get_rooms() -> Array[GRoom]:
		return __rooms.value


	func clear_rooms() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__rooms.value.clear()


	func add_rooms() -> GRoom:
		var element = GRoom.new()
		__rooms.value.append(element)
		return element


	var __player_speed_holding_scale: PBField


	func has_player_speed_holding_scale() -> bool:
		if __player_speed_holding_scale.value != null:
			return true
		return false


	func get_player_speed_holding_scale() -> float:
		return __player_speed_holding_scale.value


	func clear_player_speed_holding_scale() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__player_speed_holding_scale.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_player_speed_holding_scale(value: float) -> void:
		__player_speed_holding_scale.value = value


	var __player_speed_inside_enemies_scale: PBField


	func has_player_speed_inside_enemies_scale() -> bool:
		if __player_speed_inside_enemies_scale.value != null:
			return true
		return false


	func get_player_speed_inside_enemies_scale() -> float:
		return __player_speed_inside_enemies_scale.value


	func clear_player_speed_inside_enemies_scale() -> void:
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__player_speed_inside_enemies_scale.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_player_speed_inside_enemies_scale(value: float) -> void:
		__player_speed_inside_enemies_scale.value = value


	var __player_roll_duration_seconds: PBField


	func has_player_roll_duration_seconds() -> bool:
		if __player_roll_duration_seconds.value != null:
			return true
		return false


	func get_player_roll_duration_seconds() -> float:
		return __player_roll_duration_seconds.value


	func clear_player_roll_duration_seconds() -> void:
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__player_roll_duration_seconds.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_player_roll_duration_seconds(value: float) -> void:
		__player_roll_duration_seconds.value = value


	var __player_roll_distance: PBField


	func has_player_roll_distance() -> bool:
		if __player_roll_distance.value != null:
			return true
		return false


	func get_player_roll_distance() -> float:
		return __player_roll_distance.value


	func clear_player_roll_distance() -> void:
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__player_roll_distance.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_player_roll_distance(value: float) -> void:
		__player_roll_distance.value = value


	var __player_roll_pow: PBField


	func has_player_roll_pow() -> bool:
		if __player_roll_pow.value != null:
			return true
		return false


	func get_player_roll_pow() -> float:
		return __player_roll_pow.value


	func clear_player_roll_pow() -> void:
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__player_roll_pow.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_player_roll_pow(value: float) -> void:
		__player_roll_pow.value = value


	var __player_stamina_charges: PBField


	func has_player_stamina_charges() -> bool:
		if __player_stamina_charges.value != null:
			return true
		return false


	func get_player_stamina_charges() -> int:
		return __player_stamina_charges.value


	func clear_player_stamina_charges() -> void:
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__player_stamina_charges.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_player_stamina_charges(value: int) -> void:
		__player_stamina_charges.value = value


	var __player_stamina_regen_seconds: PBField


	func has_player_stamina_regen_seconds() -> bool:
		if __player_stamina_regen_seconds.value != null:
			return true
		return false


	func get_player_stamina_regen_seconds() -> float:
		return __player_stamina_regen_seconds.value


	func clear_player_stamina_regen_seconds() -> void:
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__player_stamina_regen_seconds.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_player_stamina_regen_seconds(value: float) -> void:
		__player_stamina_regen_seconds.value = value


	var __player_holding_stamina_regen_scale: PBField


	func has_player_holding_stamina_regen_scale() -> bool:
		if __player_holding_stamina_regen_scale.value != null:
			return true
		return false


	func get_player_holding_stamina_regen_scale() -> float:
		return __player_holding_stamina_regen_scale.value


	func clear_player_holding_stamina_regen_scale() -> void:
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__player_holding_stamina_regen_scale.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_player_holding_stamina_regen_scale(value: float) -> void:
		__player_holding_stamina_regen_scale.value = value


	var __creatures_push_radius: PBField


	func has_creatures_push_radius() -> bool:
		if __creatures_push_radius.value != null:
			return true
		return false


	func get_creatures_push_radius() -> float:
		return __creatures_push_radius.value


	func clear_creatures_push_radius() -> void:
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__creatures_push_radius.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_creatures_push_radius(value: float) -> void:
		__creatures_push_radius.value = value


	var __creatures_push_force: PBField


	func has_creatures_push_force() -> bool:
		if __creatures_push_force.value != null:
			return true
		return false


	func get_creatures_push_force() -> float:
		return __creatures_push_force.value


	func clear_creatures_push_force() -> void:
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__creatures_push_force.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_creatures_push_force(value: float) -> void:
		__creatures_push_force.value = value


	var __arrow_speed_min: PBField


	func has_arrow_speed_min() -> bool:
		if __arrow_speed_min.value != null:
			return true
		return false


	func get_arrow_speed_min() -> float:
		return __arrow_speed_min.value


	func clear_arrow_speed_min() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__arrow_speed_min.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_arrow_speed_min(value: float) -> void:
		__arrow_speed_min.value = value


	var __arrow_speed_max: PBField


	func has_arrow_speed_max() -> bool:
		if __arrow_speed_max.value != null:
			return true
		return false


	func get_arrow_speed_max() -> float:
		return __arrow_speed_max.value


	func clear_arrow_speed_max() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__arrow_speed_max.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_arrow_speed_max(value: float) -> void:
		__arrow_speed_max.value = value


	var __arrow_damage_min: PBField


	func has_arrow_damage_min() -> bool:
		if __arrow_damage_min.value != null:
			return true
		return false


	func get_arrow_damage_min() -> int:
		return __arrow_damage_min.value


	func clear_arrow_damage_min() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__arrow_damage_min.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_arrow_damage_min(value: int) -> void:
		__arrow_damage_min.value = value


	var __arrow_damage_max: PBField


	func has_arrow_damage_max() -> bool:
		if __arrow_damage_max.value != null:
			return true
		return false


	func get_arrow_damage_max() -> int:
		return __arrow_damage_max.value


	func clear_arrow_damage_max() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__arrow_damage_max.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_arrow_damage_max(value: int) -> void:
		__arrow_damage_max.value = value


	var __shooting_min_seconds: PBField


	func has_shooting_min_seconds() -> bool:
		if __shooting_min_seconds.value != null:
			return true
		return false


	func get_shooting_min_seconds() -> float:
		return __shooting_min_seconds.value


	func clear_shooting_min_seconds() -> void:
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__shooting_min_seconds.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_shooting_min_seconds(value: float) -> void:
		__shooting_min_seconds.value = value


	var __shooting_max_seconds: PBField


	func has_shooting_max_seconds() -> bool:
		if __shooting_max_seconds.value != null:
			return true
		return false


	func get_shooting_max_seconds() -> float:
		return __shooting_max_seconds.value


	func clear_shooting_max_seconds() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__shooting_max_seconds.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_shooting_max_seconds(value: float) -> void:
		__shooting_max_seconds.value = value


	var __world_size: PBField


	func has_world_size() -> bool:
		if __world_size.value != null:
			return true
		return false


	func get_world_size() -> GV2i:
		return __world_size.value


	func clear_world_size() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__world_size.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]


	func new_world_size() -> GV2i:
		__world_size.value = GV2i.new()
		return __world_size.value


	var __progression_size: PBField


	func has_progression_size() -> bool:
		if __progression_size.value != null:
			return true
		return false


	func get_progression_size() -> GV2i:
		return __progression_size.value


	func clear_progression_size() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__progression_size.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]


	func new_progression_size() -> GV2i:
		__progression_size.value = GV2i.new()
		return __progression_size.value


	var __progression: PBField


	func get_progression() -> Array[GProgression]:
		return __progression.value


	func clear_progression() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__progression.value.clear()


	func add_progression() -> GProgression:
		var element = GProgression.new()
		__progression.value.append(element)
		return element


	var __creatures: PBField


	func get_creatures() -> Array[GCreature]:
		return __creatures.value


	func clear_creatures() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__creatures.value.clear()


	func add_creatures() -> GCreature:
		var element = GCreature.new()
		__creatures.value.append(element)
		return element


	func _to_string() -> String:
		return PBPacker.message_to_string(data)


	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)


	func from_bytes(bytes: PackedByteArray, offset: int = 0, limit: int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result

################ USER DATA END #################
enum GProgressionType {
	INVALID,
	SKILL_HP,
	SKILL_MANA,
	SKILL_ATTACK,
	SKILL_ARMOR,
	SKILL_MAGIC_ATTACK,
	CRAFT_BLACKSMITH,
	CRAFT_WITCH,
	CRAFT_ENGINEER,
	CLASS_HEAVY_KNIGHT,
	CLASS_BARBARIAN,
	COUNT,
}

enum GCreatureType {
	INVALID,
	PLAYER,
	MOB_SHOOTER,
	MOB_BONKER,
	COUNT,
}
