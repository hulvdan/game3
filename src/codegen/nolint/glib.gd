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
	# get_tree().debug_collisions_hint = glib.v.get_debug_collisions() != 0


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


class GCreatureToSpawn:
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

		__size = PBField.new("size", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __size
		service.func_ref = Callable(self, "new_size")
		data[__size.tag] = service

		__direction = PBField.new("direction", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
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
		data[2].state = PB_SERVICE_STATE.UNFILLED
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
		data[3].state = PB_SERVICE_STATE.UNFILLED
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


class GSpike:
	func _init():
		var service

		__pos = PBField.new("pos", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __pos
		service.func_ref = Callable(self, "new_pos")
		data[__pos.tag] = service


	var data = { }

	var __pos: PBField


	func has_pos() -> bool:
		if __pos.value != null:
			return true
		return false


	func get_pos() -> GV2:
		return __pos.value


	func clear_pos() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
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


class GRoomInteractable:
	func _init():
		var service

		__interactable_type = PBField.new("interactable_type", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __interactable_type
		data[__interactable_type.tag] = service

		__pos = PBField.new("pos", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __pos
		service.func_ref = Callable(self, "new_pos")
		data[__pos.tag] = service


	var data = { }

	var __interactable_type: PBField


	func has_interactable_type() -> bool:
		if __interactable_type.value != null:
			return true
		return false


	func get_interactable_type() -> int:
		return __interactable_type.value


	func clear_interactable_type() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__interactable_type.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_interactable_type(value: int) -> void:
		__interactable_type.value = value


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

		var __spikes_default: Array[GSpike] = []
		__spikes = PBField.new("spikes", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 5, true, __spikes_default)
		service = PBServiceField.new()
		service.field = __spikes
		service.func_ref = Callable(self, "add_spikes")
		data[__spikes.tag] = service

		var __interactables_default: Array[GRoomInteractable] = []
		__interactables = PBField.new("interactables", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 6, true, __interactables_default)
		service = PBServiceField.new()
		service.field = __interactables
		service.func_ref = Callable(self, "add_interactables")
		data[__interactables.tag] = service

		var __creatures_default: Array[GCreatureToSpawn] = []
		__creatures = PBField.new("creatures", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 7, true, __creatures_default)
		service = PBServiceField.new()
		service.field = __creatures
		service.func_ref = Callable(self, "add_creatures")
		data[__creatures.tag] = service


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


	var __spikes: PBField


	func get_spikes() -> Array[GSpike]:
		return __spikes.value


	func clear_spikes() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__spikes.value.clear()


	func add_spikes() -> GSpike:
		var element = GSpike.new()
		__spikes.value.append(element)
		return element


	var __interactables: PBField


	func get_interactables() -> Array[GRoomInteractable]:
		return __interactables.value


	func clear_interactables() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__interactables.value.clear()


	func add_interactables() -> GRoomInteractable:
		var element = GRoomInteractable.new()
		__interactables.value.append(element)
		return element


	var __creatures: PBField


	func get_creatures() -> Array[GCreatureToSpawn]:
		return __creatures.value


	func clear_creatures() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__creatures.value.clear()


	func add_creatures() -> GCreatureToSpawn:
		var element = GCreatureToSpawn.new()
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


class GAttackPolygon:
	func _init():
		var service

		__distance_min = PBField.new("distance_min", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __distance_min
		data[__distance_min.tag] = service

		__distance_max = PBField.new("distance_max", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __distance_max
		data[__distance_max.tag] = service

		__angle = PBField.new("angle", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __angle
		data[__angle.tag] = service

		__anchor_x = PBField.new("anchor_x", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __anchor_x
		data[__anchor_x.tag] = service


	var data = { }

	var __distance_min: PBField


	func has_distance_min() -> bool:
		if __distance_min.value != null:
			return true
		return false


	func get_distance_min() -> float:
		return __distance_min.value


	func clear_distance_min() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__distance_min.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_distance_min(value: float) -> void:
		__distance_min.value = value


	var __distance_max: PBField


	func has_distance_max() -> bool:
		if __distance_max.value != null:
			return true
		return false


	func get_distance_max() -> float:
		return __distance_max.value


	func clear_distance_max() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__distance_max.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_distance_max(value: float) -> void:
		__distance_max.value = value


	var __angle: PBField


	func has_angle() -> bool:
		if __angle.value != null:
			return true
		return false


	func get_angle() -> float:
		return __angle.value


	func clear_angle() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__angle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_angle(value: float) -> void:
		__angle.value = value


	var __anchor_x: PBField


	func has_anchor_x() -> bool:
		if __anchor_x.value != null:
			return true
		return false


	func get_anchor_x() -> float:
		return __anchor_x.value


	func clear_anchor_x() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__anchor_x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_anchor_x(value: float) -> void:
		__anchor_x.value = value


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


class GAttackCircle:
	func _init():
		var service

		__radius = PBField.new("radius", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __radius
		data[__radius.tag] = service

		__anchor_x = PBField.new("anchor_x", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __anchor_x
		data[__anchor_x.tag] = service


	var data = { }

	var __radius: PBField


	func has_radius() -> bool:
		if __radius.value != null:
			return true
		return false


	func get_radius() -> float:
		return __radius.value


	func clear_radius() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__radius.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_radius(value: float) -> void:
		__radius.value = value


	var __anchor_x: PBField


	func has_anchor_x() -> bool:
		if __anchor_x.value != null:
			return true
		return false


	func get_anchor_x() -> float:
		return __anchor_x.value


	func clear_anchor_x() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__anchor_x.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_anchor_x(value: float) -> void:
		__anchor_x.value = value


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


class GCreatureDrop:
	func _init():
		var service

		__item_type = PBField.new("item_type", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __item_type
		data[__item_type.tag] = service

		__min = PBField.new("min", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __min
		data[__min.tag] = service

		__max = PBField.new("max", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __max
		data[__max.tag] = service


	var data = { }

	var __item_type: PBField


	func has_item_type() -> bool:
		if __item_type.value != null:
			return true
		return false


	func get_item_type() -> int:
		return __item_type.value


	func clear_item_type() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__item_type.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_item_type(value: int) -> void:
		__item_type.value = value


	var __min: PBField


	func has_min() -> bool:
		if __min.value != null:
			return true
		return false


	func get_min() -> int:
		return __min.value


	func clear_min() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__min.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_min(value: int) -> void:
		__min.value = value


	var __max: PBField


	func has_max() -> bool:
		if __max.value != null:
			return true
		return false


	func get_max() -> int:
		return __max.value


	func clear_max() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__max.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_max(value: int) -> void:
		__max.value = value


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


class GTag:
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


class GTagValue:
	func _init():
		var service

		__tag_type = PBField.new("tag_type", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __tag_type
		data[__tag_type.tag] = service

		__i1 = PBField.new("i1", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __i1
		data[__i1.tag] = service

		__i2 = PBField.new("i2", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __i2
		data[__i2.tag] = service

		__i3 = PBField.new("i3", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __i3
		data[__i3.tag] = service

		__i4 = PBField.new("i4", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __i4
		data[__i4.tag] = service

		__i5 = PBField.new("i5", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __i5
		data[__i5.tag] = service

		__i6 = PBField.new("i6", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __i6
		data[__i6.tag] = service

		__f1 = PBField.new("f1", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __f1
		data[__f1.tag] = service

		__f2 = PBField.new("f2", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __f2
		data[__f2.tag] = service

		__f3 = PBField.new("f3", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __f3
		data[__f3.tag] = service

		__f4 = PBField.new("f4", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __f4
		data[__f4.tag] = service

		__f5 = PBField.new("f5", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 12, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __f5
		data[__f5.tag] = service

		__f6 = PBField.new("f6", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 13, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __f6
		data[__f6.tag] = service

		__projectile_type = PBField.new("projectile_type", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 14, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __projectile_type
		data[__projectile_type.tag] = service

		__creature_type = PBField.new("creature_type", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 15, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __creature_type
		data[__creature_type.tag] = service

		__team_flags = PBField.new("team_flags", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 16, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __team_flags
		data[__team_flags.tag] = service


	var data = { }

	var __tag_type: PBField


	func has_tag_type() -> bool:
		if __tag_type.value != null:
			return true
		return false


	func get_tag_type() -> int:
		return __tag_type.value


	func clear_tag_type() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__tag_type.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_tag_type(value: int) -> void:
		__tag_type.value = value


	var __i1: PBField


	func has_i1() -> bool:
		if __i1.value != null:
			return true
		return false


	func get_i1() -> int:
		return __i1.value


	func clear_i1() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__i1.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_i1(value: int) -> void:
		__i1.value = value


	var __i2: PBField


	func has_i2() -> bool:
		if __i2.value != null:
			return true
		return false


	func get_i2() -> int:
		return __i2.value


	func clear_i2() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__i2.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_i2(value: int) -> void:
		__i2.value = value


	var __i3: PBField


	func has_i3() -> bool:
		if __i3.value != null:
			return true
		return false


	func get_i3() -> int:
		return __i3.value


	func clear_i3() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__i3.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_i3(value: int) -> void:
		__i3.value = value


	var __i4: PBField


	func has_i4() -> bool:
		if __i4.value != null:
			return true
		return false


	func get_i4() -> int:
		return __i4.value


	func clear_i4() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__i4.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_i4(value: int) -> void:
		__i4.value = value


	var __i5: PBField


	func has_i5() -> bool:
		if __i5.value != null:
			return true
		return false


	func get_i5() -> int:
		return __i5.value


	func clear_i5() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__i5.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_i5(value: int) -> void:
		__i5.value = value


	var __i6: PBField


	func has_i6() -> bool:
		if __i6.value != null:
			return true
		return false


	func get_i6() -> int:
		return __i6.value


	func clear_i6() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__i6.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_i6(value: int) -> void:
		__i6.value = value


	var __f1: PBField


	func has_f1() -> bool:
		if __f1.value != null:
			return true
		return false


	func get_f1() -> float:
		return __f1.value


	func clear_f1() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__f1.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_f1(value: float) -> void:
		__f1.value = value


	var __f2: PBField


	func has_f2() -> bool:
		if __f2.value != null:
			return true
		return false


	func get_f2() -> float:
		return __f2.value


	func clear_f2() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__f2.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_f2(value: float) -> void:
		__f2.value = value


	var __f3: PBField


	func has_f3() -> bool:
		if __f3.value != null:
			return true
		return false


	func get_f3() -> float:
		return __f3.value


	func clear_f3() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__f3.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_f3(value: float) -> void:
		__f3.value = value


	var __f4: PBField


	func has_f4() -> bool:
		if __f4.value != null:
			return true
		return false


	func get_f4() -> float:
		return __f4.value


	func clear_f4() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__f4.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_f4(value: float) -> void:
		__f4.value = value


	var __f5: PBField


	func has_f5() -> bool:
		if __f5.value != null:
			return true
		return false


	func get_f5() -> float:
		return __f5.value


	func clear_f5() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__f5.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_f5(value: float) -> void:
		__f5.value = value


	var __f6: PBField


	func has_f6() -> bool:
		if __f6.value != null:
			return true
		return false


	func get_f6() -> float:
		return __f6.value


	func clear_f6() -> void:
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__f6.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_f6(value: float) -> void:
		__f6.value = value


	var __projectile_type: PBField


	func has_projectile_type() -> bool:
		if __projectile_type.value != null:
			return true
		return false


	func get_projectile_type() -> int:
		return __projectile_type.value


	func clear_projectile_type() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__projectile_type.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_projectile_type(value: int) -> void:
		__projectile_type.value = value


	var __creature_type: PBField


	func has_creature_type() -> bool:
		if __creature_type.value != null:
			return true
		return false


	func get_creature_type() -> int:
		return __creature_type.value


	func clear_creature_type() -> void:
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__creature_type.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_creature_type(value: int) -> void:
		__creature_type.value = value


	var __team_flags: PBField


	func has_team_flags() -> bool:
		if __team_flags.value != null:
			return true
		return false


	func get_team_flags() -> int:
		return __team_flags.value


	func clear_team_flags() -> void:
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__team_flags.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_team_flags(value: int) -> void:
		__team_flags.value = value


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


class GAttackMelee:
	func _init():
		var service

		__damage = PBField.new("damage", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __damage
		data[__damage.tag] = service

		__damage_stamina = PBField.new("damage_stamina", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __damage_stamina
		service.func_ref = Callable(self, "new_damage_stamina")
		data[__damage_stamina.tag] = service

		__evade_flags = PBField.new("evade_flags", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __evade_flags
		data[__evade_flags.tag] = service

		__collider_type = PBField.new("collider_type", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __collider_type
		data[__collider_type.tag] = service

		__starts_at = PBField.new("starts_at", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __starts_at
		data[__starts_at.tag] = service

		__ends_at = PBField.new("ends_at", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __ends_at
		data[__ends_at.tag] = service

		__polygon = PBField.new("polygon", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __polygon
		service.func_ref = Callable(self, "new_polygon")
		data[__polygon.tag] = service

		__circle = PBField.new("circle", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __circle
		service.func_ref = Callable(self, "new_circle")
		data[__circle.tag] = service


	var data = { }

	var __damage: PBField


	func has_damage() -> bool:
		if __damage.value != null:
			return true
		return false


	func get_damage() -> int:
		return __damage.value


	func clear_damage() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__damage.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_damage(value: int) -> void:
		__damage.value = value


	var __damage_stamina: PBField


	func has_damage_stamina() -> bool:
		if __damage_stamina.value != null:
			return true
		return false


	func get_damage_stamina() -> GStaminaCost:
		return __damage_stamina.value


	func clear_damage_stamina() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__damage_stamina.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]


	func new_damage_stamina() -> GStaminaCost:
		__damage_stamina.value = GStaminaCost.new()
		return __damage_stamina.value


	var __evade_flags: PBField


	func has_evade_flags() -> bool:
		if __evade_flags.value != null:
			return true
		return false


	func get_evade_flags() -> int:
		return __evade_flags.value


	func clear_evade_flags() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__evade_flags.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_evade_flags(value: int) -> void:
		__evade_flags.value = value


	var __collider_type: PBField


	func has_collider_type() -> bool:
		if __collider_type.value != null:
			return true
		return false


	func get_collider_type() -> int:
		return __collider_type.value


	func clear_collider_type() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__collider_type.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_collider_type(value: int) -> void:
		__collider_type.value = value


	var __starts_at: PBField


	func has_starts_at() -> bool:
		if __starts_at.value != null:
			return true
		return false


	func get_starts_at() -> float:
		return __starts_at.value


	func clear_starts_at() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__starts_at.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_starts_at(value: float) -> void:
		__starts_at.value = value


	var __ends_at: PBField


	func has_ends_at() -> bool:
		if __ends_at.value != null:
			return true
		return false


	func get_ends_at() -> float:
		return __ends_at.value


	func clear_ends_at() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__ends_at.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_ends_at(value: float) -> void:
		__ends_at.value = value


	var __polygon: PBField


	func has_polygon() -> bool:
		if __polygon.value != null:
			return true
		return false


	func get_polygon() -> GAttackPolygon:
		return __polygon.value


	func clear_polygon() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__polygon.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]


	func new_polygon() -> GAttackPolygon:
		__polygon.value = GAttackPolygon.new()
		return __polygon.value


	var __circle: PBField


	func has_circle() -> bool:
		if __circle.value != null:
			return true
		return false


	func get_circle() -> GAttackCircle:
		return __circle.value


	func clear_circle() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__circle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]


	func new_circle() -> GAttackCircle:
		__circle.value = GAttackCircle.new()
		return __circle.value


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


class GStaminaCost:
	func _init():
		var service

		__flat = PBField.new("flat", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __flat
		data[__flat.tag] = service

		__rally_discard_mult_pre = PBField.new("rally_discard_mult_pre", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __rally_discard_mult_pre
		data[__rally_discard_mult_pre.tag] = service

		__rally = PBField.new("rally", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __rally
		data[__rally.tag] = service

		__rally_discard_mult_post = PBField.new("rally_discard_mult_post", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __rally_discard_mult_post
		data[__rally_discard_mult_post.tag] = service


	var data = { }

	var __flat: PBField


	func has_flat() -> bool:
		if __flat.value != null:
			return true
		return false


	func get_flat() -> float:
		return __flat.value


	func clear_flat() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__flat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_flat(value: float) -> void:
		__flat.value = value


	var __rally_discard_mult_pre: PBField


	func has_rally_discard_mult_pre() -> bool:
		if __rally_discard_mult_pre.value != null:
			return true
		return false


	func get_rally_discard_mult_pre() -> float:
		return __rally_discard_mult_pre.value


	func clear_rally_discard_mult_pre() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__rally_discard_mult_pre.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_rally_discard_mult_pre(value: float) -> void:
		__rally_discard_mult_pre.value = value


	var __rally: PBField


	func has_rally() -> bool:
		if __rally.value != null:
			return true
		return false


	func get_rally() -> float:
		return __rally.value


	func clear_rally() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__rally.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_rally(value: float) -> void:
		__rally.value = value


	var __rally_discard_mult_post: PBField


	func has_rally_discard_mult_post() -> bool:
		if __rally_discard_mult_post.value != null:
			return true
		return false


	func get_rally_discard_mult_post() -> float:
		return __rally_discard_mult_post.value


	func clear_rally_discard_mult_post() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__rally_discard_mult_post.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_rally_discard_mult_post(value: float) -> void:
		__rally_discard_mult_post.value = value


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


class GProjectileSpawn:
	func _init():
		var service

		__at = PBField.new("at", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __at
		data[__at.tag] = service

		__angle = PBField.new("angle", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __angle
		data[__angle.tag] = service


	var data = { }

	var __at: PBField


	func has_at() -> bool:
		if __at.value != null:
			return true
		return false


	func get_at() -> float:
		return __at.value


	func clear_at() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__at.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_at(value: float) -> void:
		__at.value = value


	var __angle: PBField


	func has_angle() -> bool:
		if __angle.value != null:
			return true
		return false


	func get_angle() -> float:
		return __angle.value


	func clear_angle() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__angle.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_angle(value: float) -> void:
		__angle.value = value


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


class GAttack:
	func _init():
		var service

		__duration = PBField.new("duration", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __duration
		data[__duration.tag] = service

		__cooldown_min = PBField.new("cooldown_min", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __cooldown_min
		data[__cooldown_min.tag] = service

		__cooldown_max = PBField.new("cooldown_max", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __cooldown_max
		data[__cooldown_max.tag] = service

		__distance = PBField.new("distance", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __distance
		data[__distance.tag] = service

		__movement_scale = PBField.new("movement_scale", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __movement_scale
		data[__movement_scale.tag] = service

		__stamina_cost = PBField.new("stamina_cost", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __stamina_cost
		service.func_ref = Callable(self, "new_stamina_cost")
		data[__stamina_cost.tag] = service

		__stops_tracking_at = PBField.new("stops_tracking_at", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __stops_tracking_at
		data[__stops_tracking_at.tag] = service

		__projectile_type = PBField.new("projectile_type", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __projectile_type
		data[__projectile_type.tag] = service

		var __projectile_spawns_default: Array[GProjectileSpawn] = []
		__projectile_spawns = PBField.new("projectile_spawns", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 9, true, __projectile_spawns_default)
		service = PBServiceField.new()
		service.field = __projectile_spawns
		service.func_ref = Callable(self, "add_projectile_spawns")
		data[__projectile_spawns.tag] = service

		__melee = PBField.new("melee", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __melee
		service.func_ref = Callable(self, "new_melee")
		data[__melee.tag] = service

		var __tags_default: Array[GTagValue] = []
		__tags = PBField.new("tags", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 11, true, __tags_default)
		service = PBServiceField.new()
		service.field = __tags
		service.func_ref = Callable(self, "add_tags")
		data[__tags.tag] = service


	var data = { }

	var __duration: PBField


	func has_duration() -> bool:
		if __duration.value != null:
			return true
		return false


	func get_duration() -> float:
		return __duration.value


	func clear_duration() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__duration.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_duration(value: float) -> void:
		__duration.value = value


	var __cooldown_min: PBField


	func has_cooldown_min() -> bool:
		if __cooldown_min.value != null:
			return true
		return false


	func get_cooldown_min() -> float:
		return __cooldown_min.value


	func clear_cooldown_min() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__cooldown_min.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_cooldown_min(value: float) -> void:
		__cooldown_min.value = value


	var __cooldown_max: PBField


	func has_cooldown_max() -> bool:
		if __cooldown_max.value != null:
			return true
		return false


	func get_cooldown_max() -> float:
		return __cooldown_max.value


	func clear_cooldown_max() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__cooldown_max.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_cooldown_max(value: float) -> void:
		__cooldown_max.value = value


	var __distance: PBField


	func has_distance() -> bool:
		if __distance.value != null:
			return true
		return false


	func get_distance() -> float:
		return __distance.value


	func clear_distance() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__distance.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_distance(value: float) -> void:
		__distance.value = value


	var __movement_scale: PBField


	func has_movement_scale() -> bool:
		if __movement_scale.value != null:
			return true
		return false


	func get_movement_scale() -> float:
		return __movement_scale.value


	func clear_movement_scale() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__movement_scale.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_movement_scale(value: float) -> void:
		__movement_scale.value = value


	var __stamina_cost: PBField


	func has_stamina_cost() -> bool:
		if __stamina_cost.value != null:
			return true
		return false


	func get_stamina_cost() -> GStaminaCost:
		return __stamina_cost.value


	func clear_stamina_cost() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__stamina_cost.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]


	func new_stamina_cost() -> GStaminaCost:
		__stamina_cost.value = GStaminaCost.new()
		return __stamina_cost.value


	var __stops_tracking_at: PBField


	func has_stops_tracking_at() -> bool:
		if __stops_tracking_at.value != null:
			return true
		return false


	func get_stops_tracking_at() -> float:
		return __stops_tracking_at.value


	func clear_stops_tracking_at() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__stops_tracking_at.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_stops_tracking_at(value: float) -> void:
		__stops_tracking_at.value = value


	var __projectile_type: PBField


	func has_projectile_type() -> bool:
		if __projectile_type.value != null:
			return true
		return false


	func get_projectile_type() -> int:
		return __projectile_type.value


	func clear_projectile_type() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__projectile_type.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_projectile_type(value: int) -> void:
		__projectile_type.value = value


	var __projectile_spawns: PBField


	func get_projectile_spawns() -> Array[GProjectileSpawn]:
		return __projectile_spawns.value


	func clear_projectile_spawns() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__projectile_spawns.value.clear()


	func add_projectile_spawns() -> GProjectileSpawn:
		var element = GProjectileSpawn.new()
		__projectile_spawns.value.append(element)
		return element


	var __melee: PBField


	func has_melee() -> bool:
		if __melee.value != null:
			return true
		return false


	func get_melee() -> GAttackMelee:
		return __melee.value


	func clear_melee() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__melee.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]


	func new_melee() -> GAttackMelee:
		__melee.value = GAttackMelee.new()
		return __melee.value


	var __tags: PBField


	func get_tags() -> Array[GTagValue]:
		return __tags.value


	func clear_tags() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__tags.value.clear()


	func add_tags() -> GTagValue:
		var element = GTagValue.new()
		__tags.value.append(element)
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


class GAbility:
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

		__attack = PBField.new("attack", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __attack
		service.func_ref = Callable(self, "new_attack")
		data[__attack.tag] = service

		__recovering_attacks = PBField.new("recovering_attacks", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __recovering_attacks
		data[__recovering_attacks.tag] = service


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


	var __attack: PBField


	func has_attack() -> bool:
		if __attack.value != null:
			return true
		return false


	func get_attack() -> GAttack:
		return __attack.value


	func clear_attack() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__attack.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]


	func new_attack() -> GAttack:
		__attack.value = GAttack.new()
		return __attack.value


	var __recovering_attacks: PBField


	func has_recovering_attacks() -> bool:
		if __recovering_attacks.value != null:
			return true
		return false


	func get_recovering_attacks() -> int:
		return __recovering_attacks.value


	func clear_recovering_attacks() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__recovering_attacks.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_recovering_attacks(value: int) -> void:
		__recovering_attacks.value = value


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

		var __drops_default: Array[GCreatureDrop] = []
		__drops = PBField.new("drops", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 7, true, __drops_default)
		service = PBServiceField.new()
		service.field = __drops
		service.func_ref = Callable(self, "add_drops")
		data[__drops.tag] = service

		var __attacks_default: Array[GAttack] = []
		__attacks = PBField.new("attacks", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 8, true, __attacks_default)
		service = PBServiceField.new()
		service.field = __attacks
		service.func_ref = Callable(self, "add_attacks")
		data[__attacks.tag] = service

		var __ability_types_default: Array[int] = []
		__ability_types = PBField.new("ability_types", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 9, true, __ability_types_default)
		service = PBServiceField.new()
		service.field = __ability_types
		data[__ability_types.tag] = service


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


	var __drops: PBField


	func get_drops() -> Array[GCreatureDrop]:
		return __drops.value


	func clear_drops() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__drops.value.clear()


	func add_drops() -> GCreatureDrop:
		var element = GCreatureDrop.new()
		__drops.value.append(element)
		return element


	var __attacks: PBField


	func get_attacks() -> Array[GAttack]:
		return __attacks.value


	func clear_attacks() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__attacks.value.clear()


	func add_attacks() -> GAttack:
		var element = GAttack.new()
		__attacks.value.append(element)
		return element


	var __ability_types: PBField


	func get_ability_types() -> Array[int]:
		return __ability_types.value


	func clear_ability_types() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__ability_types.value.clear()


	func add_ability_types(value: int) -> void:
		__ability_types.value.append(value)


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


class GDamage:
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


class GEvade:
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


class GTeam:
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


class GItem:
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


class GCollectible:
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

		__item_type = PBField.new("item_type", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __item_type
		data[__item_type.tag] = service


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


	var __item_type: PBField


	func has_item_type() -> bool:
		if __item_type.value != null:
			return true
		return false


	func get_item_type() -> int:
		return __item_type.value


	func clear_item_type() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__item_type.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_item_type(value: int) -> void:
		__item_type.value = value


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


class GProjectileFly:
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


class GProjectile:
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

		__damage = PBField.new("damage", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __damage
		data[__damage.tag] = service

		__damage_stamina = PBField.new("damage_stamina", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __damage_stamina
		service.func_ref = Callable(self, "new_damage_stamina")
		data[__damage_stamina.tag] = service

		__evade_flags = PBField.new("evade_flags", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __evade_flags
		data[__evade_flags.tag] = service

		__pierce = PBField.new("pierce", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __pierce
		data[__pierce.tag] = service

		__collider_radius = PBField.new("collider_radius", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __collider_radius
		data[__collider_radius.tag] = service

		__distance = PBField.new("distance", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __distance
		data[__distance.tag] = service

		__projectilefly_type = PBField.new("projectilefly_type", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __projectilefly_type
		data[__projectilefly_type.tag] = service

		__arc__height = PBField.new("arc__height", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __arc__height
		data[__arc__height.tag] = service

		__arc_or_area__duration = PBField.new("arc_or_area__duration", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 12, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __arc_or_area__duration
		data[__arc_or_area__duration.tag] = service

		__default__speed = PBField.new("default__speed", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 13, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __default__speed
		data[__default__speed.tag] = service

		__touch_team_flags = PBField.new("touch_team_flags", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 14, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __touch_team_flags
		data[__touch_team_flags.tag] = service

		var __tags_default: Array[GTagValue] = []
		__tags = PBField.new("tags", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 15, true, __tags_default)
		service = PBServiceField.new()
		service.field = __tags
		service.func_ref = Callable(self, "add_tags")
		data[__tags.tag] = service


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


	var __damage: PBField


	func has_damage() -> bool:
		if __damage.value != null:
			return true
		return false


	func get_damage() -> int:
		return __damage.value


	func clear_damage() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__damage.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_damage(value: int) -> void:
		__damage.value = value


	var __damage_stamina: PBField


	func has_damage_stamina() -> bool:
		if __damage_stamina.value != null:
			return true
		return false


	func get_damage_stamina() -> GStaminaCost:
		return __damage_stamina.value


	func clear_damage_stamina() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__damage_stamina.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]


	func new_damage_stamina() -> GStaminaCost:
		__damage_stamina.value = GStaminaCost.new()
		return __damage_stamina.value


	var __evade_flags: PBField


	func has_evade_flags() -> bool:
		if __evade_flags.value != null:
			return true
		return false


	func get_evade_flags() -> int:
		return __evade_flags.value


	func clear_evade_flags() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__evade_flags.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_evade_flags(value: int) -> void:
		__evade_flags.value = value


	var __pierce: PBField


	func has_pierce() -> bool:
		if __pierce.value != null:
			return true
		return false


	func get_pierce() -> int:
		return __pierce.value


	func clear_pierce() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__pierce.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_pierce(value: int) -> void:
		__pierce.value = value


	var __collider_radius: PBField


	func has_collider_radius() -> bool:
		if __collider_radius.value != null:
			return true
		return false


	func get_collider_radius() -> float:
		return __collider_radius.value


	func clear_collider_radius() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__collider_radius.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_collider_radius(value: float) -> void:
		__collider_radius.value = value


	var __distance: PBField


	func has_distance() -> bool:
		if __distance.value != null:
			return true
		return false


	func get_distance() -> float:
		return __distance.value


	func clear_distance() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__distance.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_distance(value: float) -> void:
		__distance.value = value


	var __projectilefly_type: PBField


	func has_projectilefly_type() -> bool:
		if __projectilefly_type.value != null:
			return true
		return false


	func get_projectilefly_type() -> int:
		return __projectilefly_type.value


	func clear_projectilefly_type() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__projectilefly_type.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_projectilefly_type(value: int) -> void:
		__projectilefly_type.value = value


	var __arc__height: PBField


	func has_arc__height() -> bool:
		if __arc__height.value != null:
			return true
		return false


	func get_arc__height() -> float:
		return __arc__height.value


	func clear_arc__height() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__arc__height.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_arc__height(value: float) -> void:
		__arc__height.value = value


	var __arc_or_area__duration: PBField


	func has_arc_or_area__duration() -> bool:
		if __arc_or_area__duration.value != null:
			return true
		return false


	func get_arc_or_area__duration() -> float:
		return __arc_or_area__duration.value


	func clear_arc_or_area__duration() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__arc_or_area__duration.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_arc_or_area__duration(value: float) -> void:
		__arc_or_area__duration.value = value


	var __default__speed: PBField


	func has_default__speed() -> bool:
		if __default__speed.value != null:
			return true
		return false


	func get_default__speed() -> float:
		return __default__speed.value


	func clear_default__speed() -> void:
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__default__speed.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_default__speed(value: float) -> void:
		__default__speed.value = value


	var __touch_team_flags: PBField


	func has_touch_team_flags() -> bool:
		if __touch_team_flags.value != null:
			return true
		return false


	func get_touch_team_flags() -> int:
		return __touch_team_flags.value


	func clear_touch_team_flags() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__touch_team_flags.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_touch_team_flags(value: int) -> void:
		__touch_team_flags.value = value


	var __tags: PBField


	func get_tags() -> Array[GTagValue]:
		return __tags.value


	func clear_tags() -> void:
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__tags.value.clear()


	func add_tags() -> GTagValue:
		var element = GTagValue.new()
		__tags.value.append(element)
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


class GInteractable:
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

		__hp = PBField.new("hp", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __hp
		data[__hp.tag] = service

		__projectile_type = PBField.new("projectile_type", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __projectile_type
		data[__projectile_type.tag] = service

		__mass = PBField.new("mass", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __mass
		data[__mass.tag] = service


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


	var __hp: PBField


	func has_hp() -> bool:
		if __hp.value != null:
			return true
		return false


	func get_hp() -> int:
		return __hp.value


	func clear_hp() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__hp.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_hp(value: int) -> void:
		__hp.value = value


	var __projectile_type: PBField


	func has_projectile_type() -> bool:
		if __projectile_type.value != null:
			return true
		return false


	func get_projectile_type() -> int:
		return __projectile_type.value


	func clear_projectile_type() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__projectile_type.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_projectile_type(value: int) -> void:
		__projectile_type.value = value


	var __mass: PBField


	func has_mass() -> bool:
		if __mass.value != null:
			return true
		return false


	func get_mass() -> float:
		return __mass.value


	func clear_mass() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__mass.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_mass(value: float) -> void:
		__mass.value = value


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


class GMask:
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


class GConfigControls:
	func _init():
		var service

		__action_consumption_duration = PBField.new("action_consumption_duration", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __action_consumption_duration
		data[__action_consumption_duration.tag] = service


	var data = { }

	var __action_consumption_duration: PBField


	func has_action_consumption_duration() -> bool:
		if __action_consumption_duration.value != null:
			return true
		return false


	func get_action_consumption_duration() -> float:
		return __action_consumption_duration.value


	func clear_action_consumption_duration() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__action_consumption_duration.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_action_consumption_duration(value: float) -> void:
		__action_consumption_duration.value = value


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


class GConfigSpikes:
	func _init():
		var service

		__duration_seconds = PBField.new("duration_seconds", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __duration_seconds
		data[__duration_seconds.tag] = service

		__damage_starts_at = PBField.new("damage_starts_at", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __damage_starts_at
		data[__damage_starts_at.tag] = service

		__damage = PBField.new("damage", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __damage
		data[__damage.tag] = service

		__initial_evade_flags = PBField.new("initial_evade_flags", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __initial_evade_flags
		data[__initial_evade_flags.tag] = service

		__continuous_evade_flags = PBField.new("continuous_evade_flags", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __continuous_evade_flags
		data[__continuous_evade_flags.tag] = service


	var data = { }

	var __duration_seconds: PBField


	func has_duration_seconds() -> bool:
		if __duration_seconds.value != null:
			return true
		return false


	func get_duration_seconds() -> float:
		return __duration_seconds.value


	func clear_duration_seconds() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__duration_seconds.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_duration_seconds(value: float) -> void:
		__duration_seconds.value = value


	var __damage_starts_at: PBField


	func has_damage_starts_at() -> bool:
		if __damage_starts_at.value != null:
			return true
		return false


	func get_damage_starts_at() -> float:
		return __damage_starts_at.value


	func clear_damage_starts_at() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__damage_starts_at.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_damage_starts_at(value: float) -> void:
		__damage_starts_at.value = value


	var __damage: PBField


	func has_damage() -> bool:
		if __damage.value != null:
			return true
		return false


	func get_damage() -> int:
		return __damage.value


	func clear_damage() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__damage.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_damage(value: int) -> void:
		__damage.value = value


	var __initial_evade_flags: PBField


	func has_initial_evade_flags() -> bool:
		if __initial_evade_flags.value != null:
			return true
		return false


	func get_initial_evade_flags() -> int:
		return __initial_evade_flags.value


	func clear_initial_evade_flags() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__initial_evade_flags.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_initial_evade_flags(value: int) -> void:
		__initial_evade_flags.value = value


	var __continuous_evade_flags: PBField


	func has_continuous_evade_flags() -> bool:
		if __continuous_evade_flags.value != null:
			return true
		return false


	func get_continuous_evade_flags() -> int:
		return __continuous_evade_flags.value


	func clear_continuous_evade_flags() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__continuous_evade_flags.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_continuous_evade_flags(value: int) -> void:
		__continuous_evade_flags.value = value


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


class GConfigPlayer:
	func _init():
		var service

		__speed_scale__shooting = PBField.new("speed_scale__shooting", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __speed_scale__shooting
		data[__speed_scale__shooting.tag] = service

		__speed_scale__blocking = PBField.new("speed_scale__blocking", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __speed_scale__blocking
		data[__speed_scale__blocking.tag] = service

		__speed_scale__inside_enemies = PBField.new("speed_scale__inside_enemies", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __speed_scale__inside_enemies
		data[__speed_scale__inside_enemies.tag] = service

		__roll_distance = PBField.new("roll_distance", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __roll_distance
		data[__roll_distance.tag] = service

		__roll_pow = PBField.new("roll_pow", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __roll_pow
		data[__roll_pow.tag] = service

		__roll_invincibility_start = PBField.new("roll_invincibility_start", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __roll_invincibility_start
		data[__roll_invincibility_start.tag] = service

		__roll_invincibility_end = PBField.new("roll_invincibility_end", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __roll_invincibility_end
		data[__roll_invincibility_end.tag] = service

		__roll_duration_seconds = PBField.new("roll_duration_seconds", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __roll_duration_seconds
		data[__roll_duration_seconds.tag] = service

		__roll_control_return_starts_at = PBField.new("roll_control_return_starts_at", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __roll_control_return_starts_at
		data[__roll_control_return_starts_at.tag] = service

		__stamina = PBField.new("stamina", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __stamina
		data[__stamina.tag] = service

		__stamina_regen_per_second = PBField.new("stamina_regen_per_second", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __stamina_regen_per_second
		data[__stamina_regen_per_second.tag] = service

		__roll_stamina_cost = PBField.new("roll_stamina_cost", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 12, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __roll_stamina_cost
		service.func_ref = Callable(self, "new_roll_stamina_cost")
		data[__roll_stamina_cost.tag] = service

		__dodge_stamina_retrieve_percent = PBField.new("dodge_stamina_retrieve_percent", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 13, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __dodge_stamina_retrieve_percent
		data[__dodge_stamina_retrieve_percent.tag] = service

		__stamina_rally_decay_after = PBField.new("stamina_rally_decay_after", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 14, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __stamina_rally_decay_after
		data[__stamina_rally_decay_after.tag] = service

		__stamina_rally_decay_per_second = PBField.new("stamina_rally_decay_per_second", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 15, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __stamina_rally_decay_per_second
		data[__stamina_rally_decay_per_second.tag] = service

		__stamina_attack_cost = PBField.new("stamina_attack_cost", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 16, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __stamina_attack_cost
		data[__stamina_attack_cost.tag] = service

		__stamina_attack_rally_scale = PBField.new("stamina_attack_rally_scale", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 17, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __stamina_attack_rally_scale
		data[__stamina_attack_rally_scale.tag] = service

		__stamina_roll_rally_scale = PBField.new("stamina_roll_rally_scale", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 18, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __stamina_roll_rally_scale
		data[__stamina_roll_rally_scale.tag] = service

		__stamina_regen_on_kill = PBField.new("stamina_regen_on_kill", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 19, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __stamina_regen_on_kill
		data[__stamina_regen_on_kill.tag] = service

		__stamina_regen_scale__blocking = PBField.new("stamina_regen_scale__blocking", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 20, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __stamina_regen_scale__blocking
		data[__stamina_regen_scale__blocking.tag] = service

		__stamina_regen_scale__shooting = PBField.new("stamina_regen_scale__shooting", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 21, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __stamina_regen_scale__shooting
		data[__stamina_regen_scale__shooting.tag] = service

		__block__activation_start = PBField.new("block__activation_start", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 22, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __block__activation_start
		data[__block__activation_start.tag] = service

		__ki__rally_increase_per_second = PBField.new("ki__rally_increase_per_second", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 23, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __ki__rally_increase_per_second
		data[__ki__rally_increase_per_second.tag] = service

		__block__min_duration = PBField.new("block__min_duration", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 24, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __block__min_duration
		data[__block__min_duration.tag] = service

		__block__idle_after_block = PBField.new("block__idle_after_block", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 25, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __block__idle_after_block
		data[__block__idle_after_block.tag] = service

		__cooldown__block = PBField.new("cooldown__block", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 26, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __cooldown__block
		data[__cooldown__block.tag] = service

		__cooldown__roll = PBField.new("cooldown__roll", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 27, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __cooldown__roll
		data[__cooldown__roll.tag] = service

		__block__perfect_end = PBField.new("block__perfect_end", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 28, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __block__perfect_end
		data[__block__perfect_end.tag] = service

		__stamina_depletion_regen_delay = PBField.new("stamina_depletion_regen_delay", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 29, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __stamina_depletion_regen_delay
		data[__stamina_depletion_regen_delay.tag] = service

		__invincibility_after_hit_seconds = PBField.new("invincibility_after_hit_seconds", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 30, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __invincibility_after_hit_seconds
		data[__invincibility_after_hit_seconds.tag] = service


	var data = { }

	var __speed_scale__shooting: PBField


	func has_speed_scale__shooting() -> bool:
		if __speed_scale__shooting.value != null:
			return true
		return false


	func get_speed_scale__shooting() -> float:
		return __speed_scale__shooting.value


	func clear_speed_scale__shooting() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__speed_scale__shooting.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_speed_scale__shooting(value: float) -> void:
		__speed_scale__shooting.value = value


	var __speed_scale__blocking: PBField


	func has_speed_scale__blocking() -> bool:
		if __speed_scale__blocking.value != null:
			return true
		return false


	func get_speed_scale__blocking() -> float:
		return __speed_scale__blocking.value


	func clear_speed_scale__blocking() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__speed_scale__blocking.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_speed_scale__blocking(value: float) -> void:
		__speed_scale__blocking.value = value


	var __speed_scale__inside_enemies: PBField


	func has_speed_scale__inside_enemies() -> bool:
		if __speed_scale__inside_enemies.value != null:
			return true
		return false


	func get_speed_scale__inside_enemies() -> float:
		return __speed_scale__inside_enemies.value


	func clear_speed_scale__inside_enemies() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__speed_scale__inside_enemies.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_speed_scale__inside_enemies(value: float) -> void:
		__speed_scale__inside_enemies.value = value


	var __roll_distance: PBField


	func has_roll_distance() -> bool:
		if __roll_distance.value != null:
			return true
		return false


	func get_roll_distance() -> float:
		return __roll_distance.value


	func clear_roll_distance() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__roll_distance.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_roll_distance(value: float) -> void:
		__roll_distance.value = value


	var __roll_pow: PBField


	func has_roll_pow() -> bool:
		if __roll_pow.value != null:
			return true
		return false


	func get_roll_pow() -> float:
		return __roll_pow.value


	func clear_roll_pow() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__roll_pow.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_roll_pow(value: float) -> void:
		__roll_pow.value = value


	var __roll_invincibility_start: PBField


	func has_roll_invincibility_start() -> bool:
		if __roll_invincibility_start.value != null:
			return true
		return false


	func get_roll_invincibility_start() -> float:
		return __roll_invincibility_start.value


	func clear_roll_invincibility_start() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__roll_invincibility_start.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_roll_invincibility_start(value: float) -> void:
		__roll_invincibility_start.value = value


	var __roll_invincibility_end: PBField


	func has_roll_invincibility_end() -> bool:
		if __roll_invincibility_end.value != null:
			return true
		return false


	func get_roll_invincibility_end() -> float:
		return __roll_invincibility_end.value


	func clear_roll_invincibility_end() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__roll_invincibility_end.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_roll_invincibility_end(value: float) -> void:
		__roll_invincibility_end.value = value


	var __roll_duration_seconds: PBField


	func has_roll_duration_seconds() -> bool:
		if __roll_duration_seconds.value != null:
			return true
		return false


	func get_roll_duration_seconds() -> float:
		return __roll_duration_seconds.value


	func clear_roll_duration_seconds() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__roll_duration_seconds.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_roll_duration_seconds(value: float) -> void:
		__roll_duration_seconds.value = value


	var __roll_control_return_starts_at: PBField


	func has_roll_control_return_starts_at() -> bool:
		if __roll_control_return_starts_at.value != null:
			return true
		return false


	func get_roll_control_return_starts_at() -> float:
		return __roll_control_return_starts_at.value


	func clear_roll_control_return_starts_at() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__roll_control_return_starts_at.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_roll_control_return_starts_at(value: float) -> void:
		__roll_control_return_starts_at.value = value


	var __stamina: PBField


	func has_stamina() -> bool:
		if __stamina.value != null:
			return true
		return false


	func get_stamina() -> float:
		return __stamina.value


	func clear_stamina() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__stamina.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_stamina(value: float) -> void:
		__stamina.value = value


	var __stamina_regen_per_second: PBField


	func has_stamina_regen_per_second() -> bool:
		if __stamina_regen_per_second.value != null:
			return true
		return false


	func get_stamina_regen_per_second() -> float:
		return __stamina_regen_per_second.value


	func clear_stamina_regen_per_second() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__stamina_regen_per_second.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_stamina_regen_per_second(value: float) -> void:
		__stamina_regen_per_second.value = value


	var __roll_stamina_cost: PBField


	func has_roll_stamina_cost() -> bool:
		if __roll_stamina_cost.value != null:
			return true
		return false


	func get_roll_stamina_cost() -> GStaminaCost:
		return __roll_stamina_cost.value


	func clear_roll_stamina_cost() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__roll_stamina_cost.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]


	func new_roll_stamina_cost() -> GStaminaCost:
		__roll_stamina_cost.value = GStaminaCost.new()
		return __roll_stamina_cost.value


	var __dodge_stamina_retrieve_percent: PBField


	func has_dodge_stamina_retrieve_percent() -> bool:
		if __dodge_stamina_retrieve_percent.value != null:
			return true
		return false


	func get_dodge_stamina_retrieve_percent() -> float:
		return __dodge_stamina_retrieve_percent.value


	func clear_dodge_stamina_retrieve_percent() -> void:
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__dodge_stamina_retrieve_percent.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_dodge_stamina_retrieve_percent(value: float) -> void:
		__dodge_stamina_retrieve_percent.value = value


	var __stamina_rally_decay_after: PBField


	func has_stamina_rally_decay_after() -> bool:
		if __stamina_rally_decay_after.value != null:
			return true
		return false


	func get_stamina_rally_decay_after() -> float:
		return __stamina_rally_decay_after.value


	func clear_stamina_rally_decay_after() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__stamina_rally_decay_after.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_stamina_rally_decay_after(value: float) -> void:
		__stamina_rally_decay_after.value = value


	var __stamina_rally_decay_per_second: PBField


	func has_stamina_rally_decay_per_second() -> bool:
		if __stamina_rally_decay_per_second.value != null:
			return true
		return false


	func get_stamina_rally_decay_per_second() -> float:
		return __stamina_rally_decay_per_second.value


	func clear_stamina_rally_decay_per_second() -> void:
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__stamina_rally_decay_per_second.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_stamina_rally_decay_per_second(value: float) -> void:
		__stamina_rally_decay_per_second.value = value


	var __stamina_attack_cost: PBField


	func has_stamina_attack_cost() -> bool:
		if __stamina_attack_cost.value != null:
			return true
		return false


	func get_stamina_attack_cost() -> float:
		return __stamina_attack_cost.value


	func clear_stamina_attack_cost() -> void:
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__stamina_attack_cost.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_stamina_attack_cost(value: float) -> void:
		__stamina_attack_cost.value = value


	var __stamina_attack_rally_scale: PBField


	func has_stamina_attack_rally_scale() -> bool:
		if __stamina_attack_rally_scale.value != null:
			return true
		return false


	func get_stamina_attack_rally_scale() -> float:
		return __stamina_attack_rally_scale.value


	func clear_stamina_attack_rally_scale() -> void:
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__stamina_attack_rally_scale.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_stamina_attack_rally_scale(value: float) -> void:
		__stamina_attack_rally_scale.value = value


	var __stamina_roll_rally_scale: PBField


	func has_stamina_roll_rally_scale() -> bool:
		if __stamina_roll_rally_scale.value != null:
			return true
		return false


	func get_stamina_roll_rally_scale() -> float:
		return __stamina_roll_rally_scale.value


	func clear_stamina_roll_rally_scale() -> void:
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__stamina_roll_rally_scale.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_stamina_roll_rally_scale(value: float) -> void:
		__stamina_roll_rally_scale.value = value


	var __stamina_regen_on_kill: PBField


	func has_stamina_regen_on_kill() -> bool:
		if __stamina_regen_on_kill.value != null:
			return true
		return false


	func get_stamina_regen_on_kill() -> float:
		return __stamina_regen_on_kill.value


	func clear_stamina_regen_on_kill() -> void:
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__stamina_regen_on_kill.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_stamina_regen_on_kill(value: float) -> void:
		__stamina_regen_on_kill.value = value


	var __stamina_regen_scale__blocking: PBField


	func has_stamina_regen_scale__blocking() -> bool:
		if __stamina_regen_scale__blocking.value != null:
			return true
		return false


	func get_stamina_regen_scale__blocking() -> float:
		return __stamina_regen_scale__blocking.value


	func clear_stamina_regen_scale__blocking() -> void:
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__stamina_regen_scale__blocking.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_stamina_regen_scale__blocking(value: float) -> void:
		__stamina_regen_scale__blocking.value = value


	var __stamina_regen_scale__shooting: PBField


	func has_stamina_regen_scale__shooting() -> bool:
		if __stamina_regen_scale__shooting.value != null:
			return true
		return false


	func get_stamina_regen_scale__shooting() -> float:
		return __stamina_regen_scale__shooting.value


	func clear_stamina_regen_scale__shooting() -> void:
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__stamina_regen_scale__shooting.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_stamina_regen_scale__shooting(value: float) -> void:
		__stamina_regen_scale__shooting.value = value


	var __block__activation_start: PBField


	func has_block__activation_start() -> bool:
		if __block__activation_start.value != null:
			return true
		return false


	func get_block__activation_start() -> float:
		return __block__activation_start.value


	func clear_block__activation_start() -> void:
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__block__activation_start.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_block__activation_start(value: float) -> void:
		__block__activation_start.value = value


	var __ki__rally_increase_per_second: PBField


	func has_ki__rally_increase_per_second() -> bool:
		if __ki__rally_increase_per_second.value != null:
			return true
		return false


	func get_ki__rally_increase_per_second() -> float:
		return __ki__rally_increase_per_second.value


	func clear_ki__rally_increase_per_second() -> void:
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__ki__rally_increase_per_second.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_ki__rally_increase_per_second(value: float) -> void:
		__ki__rally_increase_per_second.value = value


	var __block__min_duration: PBField


	func has_block__min_duration() -> bool:
		if __block__min_duration.value != null:
			return true
		return false


	func get_block__min_duration() -> float:
		return __block__min_duration.value


	func clear_block__min_duration() -> void:
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__block__min_duration.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_block__min_duration(value: float) -> void:
		__block__min_duration.value = value


	var __block__idle_after_block: PBField


	func has_block__idle_after_block() -> bool:
		if __block__idle_after_block.value != null:
			return true
		return false


	func get_block__idle_after_block() -> float:
		return __block__idle_after_block.value


	func clear_block__idle_after_block() -> void:
		data[25].state = PB_SERVICE_STATE.UNFILLED
		__block__idle_after_block.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_block__idle_after_block(value: float) -> void:
		__block__idle_after_block.value = value


	var __cooldown__block: PBField


	func has_cooldown__block() -> bool:
		if __cooldown__block.value != null:
			return true
		return false


	func get_cooldown__block() -> float:
		return __cooldown__block.value


	func clear_cooldown__block() -> void:
		data[26].state = PB_SERVICE_STATE.UNFILLED
		__cooldown__block.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_cooldown__block(value: float) -> void:
		__cooldown__block.value = value


	var __cooldown__roll: PBField


	func has_cooldown__roll() -> bool:
		if __cooldown__roll.value != null:
			return true
		return false


	func get_cooldown__roll() -> float:
		return __cooldown__roll.value


	func clear_cooldown__roll() -> void:
		data[27].state = PB_SERVICE_STATE.UNFILLED
		__cooldown__roll.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_cooldown__roll(value: float) -> void:
		__cooldown__roll.value = value


	var __block__perfect_end: PBField


	func has_block__perfect_end() -> bool:
		if __block__perfect_end.value != null:
			return true
		return false


	func get_block__perfect_end() -> float:
		return __block__perfect_end.value


	func clear_block__perfect_end() -> void:
		data[28].state = PB_SERVICE_STATE.UNFILLED
		__block__perfect_end.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_block__perfect_end(value: float) -> void:
		__block__perfect_end.value = value


	var __stamina_depletion_regen_delay: PBField


	func has_stamina_depletion_regen_delay() -> bool:
		if __stamina_depletion_regen_delay.value != null:
			return true
		return false


	func get_stamina_depletion_regen_delay() -> float:
		return __stamina_depletion_regen_delay.value


	func clear_stamina_depletion_regen_delay() -> void:
		data[29].state = PB_SERVICE_STATE.UNFILLED
		__stamina_depletion_regen_delay.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_stamina_depletion_regen_delay(value: float) -> void:
		__stamina_depletion_regen_delay.value = value


	var __invincibility_after_hit_seconds: PBField


	func has_invincibility_after_hit_seconds() -> bool:
		if __invincibility_after_hit_seconds.value != null:
			return true
		return false


	func get_invincibility_after_hit_seconds() -> float:
		return __invincibility_after_hit_seconds.value


	func clear_invincibility_after_hit_seconds() -> void:
		data[30].state = PB_SERVICE_STATE.UNFILLED
		__invincibility_after_hit_seconds.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_invincibility_after_hit_seconds(value: float) -> void:
		__invincibility_after_hit_seconds.value = value


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

		__controls = PBField.new("controls", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __controls
		service.func_ref = Callable(self, "new_controls")
		data[__controls.tag] = service

		__player = PBField.new("player", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __player
		service.func_ref = Callable(self, "new_player")
		data[__player.tag] = service

		__spikes = PBField.new("spikes", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __spikes
		service.func_ref = Callable(self, "new_spikes")
		data[__spikes.tag] = service

		__debug_collisions = PBField.new("debug_collisions", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __debug_collisions
		data[__debug_collisions.tag] = service

		__debug_collisions__chase = PBField.new("debug_collisions__chase", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __debug_collisions__chase
		data[__debug_collisions__chase.tag] = service

		var __rooms_default: Array[GRoom] = []
		__rooms = PBField.new("rooms", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 6, true, __rooms_default)
		service = PBServiceField.new()
		service.field = __rooms
		service.func_ref = Callable(self, "add_rooms")
		data[__rooms.tag] = service

		__mob_invincibility_spikes_seconds = PBField.new("mob_invincibility_spikes_seconds", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __mob_invincibility_spikes_seconds
		data[__mob_invincibility_spikes_seconds.tag] = service

		__blocked_attack_damages_again_after = PBField.new("blocked_attack_damages_again_after", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __blocked_attack_damages_again_after
		data[__blocked_attack_damages_again_after.tag] = service

		__creatures_push_radius = PBField.new("creatures_push_radius", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __creatures_push_radius
		data[__creatures_push_radius.tag] = service

		__creatures_push_force = PBField.new("creatures_push_force", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __creatures_push_force
		data[__creatures_push_force.tag] = service

		__default_impulse_duration_seconds = PBField.new("default_impulse_duration_seconds", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __default_impulse_duration_seconds
		data[__default_impulse_duration_seconds.tag] = service

		__default_impulse_pow = PBField.new("default_impulse_pow", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 12, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __default_impulse_pow
		data[__default_impulse_pow.tag] = service

		__impulse_block_scale = PBField.new("impulse_block_scale", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 13, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = __impulse_block_scale
		data[__impulse_block_scale.tag] = service

		__world_size = PBField.new("world_size", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 14, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __world_size
		service.func_ref = Callable(self, "new_world_size")
		data[__world_size.tag] = service

		__progression_size = PBField.new("progression_size", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 15, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __progression_size
		service.func_ref = Callable(self, "new_progression_size")
		data[__progression_size.tag] = service

		var __damages_default: Array[GDamage] = []
		__damages = PBField.new("damages", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 16, true, __damages_default)
		service = PBServiceField.new()
		service.field = __damages
		service.func_ref = Callable(self, "add_damages")
		data[__damages.tag] = service

		var __evades_default: Array[GEvade] = []
		__evades = PBField.new("evades", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 17, true, __evades_default)
		service = PBServiceField.new()
		service.field = __evades
		service.func_ref = Callable(self, "add_evades")
		data[__evades.tag] = service

		var __teams_default: Array[GTeam] = []
		__teams = PBField.new("teams", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 18, true, __teams_default)
		service = PBServiceField.new()
		service.field = __teams
		service.func_ref = Callable(self, "add_teams")
		data[__teams.tag] = service

		var __progression_default: Array[GProgression] = []
		__progression = PBField.new("progression", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 19, true, __progression_default)
		service = PBServiceField.new()
		service.field = __progression
		service.func_ref = Callable(self, "add_progression")
		data[__progression.tag] = service

		var __abilities_default: Array[GAbility] = []
		__abilities = PBField.new("abilities", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 20, true, __abilities_default)
		service = PBServiceField.new()
		service.field = __abilities
		service.func_ref = Callable(self, "add_abilities")
		data[__abilities.tag] = service

		var __creatures_default: Array[GCreature] = []
		__creatures = PBField.new("creatures", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 21, true, __creatures_default)
		service = PBServiceField.new()
		service.field = __creatures
		service.func_ref = Callable(self, "add_creatures")
		data[__creatures.tag] = service

		var __items_default: Array[GItem] = []
		__items = PBField.new("items", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 22, true, __items_default)
		service = PBServiceField.new()
		service.field = __items
		service.func_ref = Callable(self, "add_items")
		data[__items.tag] = service

		var __collectibles_default: Array[GCollectible] = []
		__collectibles = PBField.new("collectibles", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 23, true, __collectibles_default)
		service = PBServiceField.new()
		service.field = __collectibles
		service.func_ref = Callable(self, "add_collectibles")
		data[__collectibles.tag] = service

		var __projectile_fly_types_default: Array[GProjectileFly] = []
		__projectile_fly_types = PBField.new("projectile_fly_types", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 24, true, __projectile_fly_types_default)
		service = PBServiceField.new()
		service.field = __projectile_fly_types
		service.func_ref = Callable(self, "add_projectile_fly_types")
		data[__projectile_fly_types.tag] = service

		var __projectiles_default: Array[GProjectile] = []
		__projectiles = PBField.new("projectiles", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 25, true, __projectiles_default)
		service = PBServiceField.new()
		service.field = __projectiles
		service.func_ref = Callable(self, "add_projectiles")
		data[__projectiles.tag] = service

		var __interactables_default: Array[GInteractable] = []
		__interactables = PBField.new("interactables", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 26, true, __interactables_default)
		service = PBServiceField.new()
		service.field = __interactables
		service.func_ref = Callable(self, "add_interactables")
		data[__interactables.tag] = service

		var __masks_default: Array[GMask] = []
		__masks = PBField.new("masks", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 27, true, __masks_default)
		service = PBServiceField.new()
		service.field = __masks
		service.func_ref = Callable(self, "add_masks")
		data[__masks.tag] = service

		var __tags_default: Array[GTag] = []
		__tags = PBField.new("tags", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 28, true, __tags_default)
		service = PBServiceField.new()
		service.field = __tags
		service.func_ref = Callable(self, "add_tags")
		data[__tags.tag] = service


	var data = { }

	var __controls: PBField


	func has_controls() -> bool:
		if __controls.value != null:
			return true
		return false


	func get_controls() -> GConfigControls:
		return __controls.value


	func clear_controls() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__controls.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]


	func new_controls() -> GConfigControls:
		__controls.value = GConfigControls.new()
		return __controls.value


	var __player: PBField


	func has_player() -> bool:
		if __player.value != null:
			return true
		return false


	func get_player() -> GConfigPlayer:
		return __player.value


	func clear_player() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__player.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]


	func new_player() -> GConfigPlayer:
		__player.value = GConfigPlayer.new()
		return __player.value


	var __spikes: PBField


	func has_spikes() -> bool:
		if __spikes.value != null:
			return true
		return false


	func get_spikes() -> GConfigSpikes:
		return __spikes.value


	func clear_spikes() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__spikes.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]


	func new_spikes() -> GConfigSpikes:
		__spikes.value = GConfigSpikes.new()
		return __spikes.value


	var __debug_collisions: PBField


	func has_debug_collisions() -> bool:
		if __debug_collisions.value != null:
			return true
		return false


	func get_debug_collisions() -> int:
		return __debug_collisions.value


	func clear_debug_collisions() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__debug_collisions.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_debug_collisions(value: int) -> void:
		__debug_collisions.value = value


	var __debug_collisions__chase: PBField


	func has_debug_collisions__chase() -> bool:
		if __debug_collisions__chase.value != null:
			return true
		return false


	func get_debug_collisions__chase() -> int:
		return __debug_collisions__chase.value


	func clear_debug_collisions__chase() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__debug_collisions__chase.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]


	func set_debug_collisions__chase(value: int) -> void:
		__debug_collisions__chase.value = value


	var __rooms: PBField


	func get_rooms() -> Array[GRoom]:
		return __rooms.value


	func clear_rooms() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__rooms.value.clear()


	func add_rooms() -> GRoom:
		var element = GRoom.new()
		__rooms.value.append(element)
		return element


	var __mob_invincibility_spikes_seconds: PBField


	func has_mob_invincibility_spikes_seconds() -> bool:
		if __mob_invincibility_spikes_seconds.value != null:
			return true
		return false


	func get_mob_invincibility_spikes_seconds() -> float:
		return __mob_invincibility_spikes_seconds.value


	func clear_mob_invincibility_spikes_seconds() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__mob_invincibility_spikes_seconds.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_mob_invincibility_spikes_seconds(value: float) -> void:
		__mob_invincibility_spikes_seconds.value = value


	var __blocked_attack_damages_again_after: PBField


	func has_blocked_attack_damages_again_after() -> bool:
		if __blocked_attack_damages_again_after.value != null:
			return true
		return false


	func get_blocked_attack_damages_again_after() -> float:
		return __blocked_attack_damages_again_after.value


	func clear_blocked_attack_damages_again_after() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__blocked_attack_damages_again_after.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_blocked_attack_damages_again_after(value: float) -> void:
		__blocked_attack_damages_again_after.value = value


	var __creatures_push_radius: PBField


	func has_creatures_push_radius() -> bool:
		if __creatures_push_radius.value != null:
			return true
		return false


	func get_creatures_push_radius() -> float:
		return __creatures_push_radius.value


	func clear_creatures_push_radius() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
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
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__creatures_push_force.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_creatures_push_force(value: float) -> void:
		__creatures_push_force.value = value


	var __default_impulse_duration_seconds: PBField


	func has_default_impulse_duration_seconds() -> bool:
		if __default_impulse_duration_seconds.value != null:
			return true
		return false


	func get_default_impulse_duration_seconds() -> float:
		return __default_impulse_duration_seconds.value


	func clear_default_impulse_duration_seconds() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__default_impulse_duration_seconds.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_default_impulse_duration_seconds(value: float) -> void:
		__default_impulse_duration_seconds.value = value


	var __default_impulse_pow: PBField


	func has_default_impulse_pow() -> bool:
		if __default_impulse_pow.value != null:
			return true
		return false


	func get_default_impulse_pow() -> float:
		return __default_impulse_pow.value


	func clear_default_impulse_pow() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__default_impulse_pow.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_default_impulse_pow(value: float) -> void:
		__default_impulse_pow.value = value


	var __impulse_block_scale: PBField


	func has_impulse_block_scale() -> bool:
		if __impulse_block_scale.value != null:
			return true
		return false


	func get_impulse_block_scale() -> float:
		return __impulse_block_scale.value


	func clear_impulse_block_scale() -> void:
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__impulse_block_scale.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FLOAT]


	func set_impulse_block_scale(value: float) -> void:
		__impulse_block_scale.value = value


	var __world_size: PBField


	func has_world_size() -> bool:
		if __world_size.value != null:
			return true
		return false


	func get_world_size() -> GV2i:
		return __world_size.value


	func clear_world_size() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
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
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__progression_size.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]


	func new_progression_size() -> GV2i:
		__progression_size.value = GV2i.new()
		return __progression_size.value


	var __damages: PBField


	func get_damages() -> Array[GDamage]:
		return __damages.value


	func clear_damages() -> void:
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__damages.value.clear()


	func add_damages() -> GDamage:
		var element = GDamage.new()
		__damages.value.append(element)
		return element


	var __evades: PBField


	func get_evades() -> Array[GEvade]:
		return __evades.value


	func clear_evades() -> void:
		data[17].state = PB_SERVICE_STATE.UNFILLED
		__evades.value.clear()


	func add_evades() -> GEvade:
		var element = GEvade.new()
		__evades.value.append(element)
		return element


	var __teams: PBField


	func get_teams() -> Array[GTeam]:
		return __teams.value


	func clear_teams() -> void:
		data[18].state = PB_SERVICE_STATE.UNFILLED
		__teams.value.clear()


	func add_teams() -> GTeam:
		var element = GTeam.new()
		__teams.value.append(element)
		return element


	var __progression: PBField


	func get_progression() -> Array[GProgression]:
		return __progression.value


	func clear_progression() -> void:
		data[19].state = PB_SERVICE_STATE.UNFILLED
		__progression.value.clear()


	func add_progression() -> GProgression:
		var element = GProgression.new()
		__progression.value.append(element)
		return element


	var __abilities: PBField


	func get_abilities() -> Array[GAbility]:
		return __abilities.value


	func clear_abilities() -> void:
		data[20].state = PB_SERVICE_STATE.UNFILLED
		__abilities.value.clear()


	func add_abilities() -> GAbility:
		var element = GAbility.new()
		__abilities.value.append(element)
		return element


	var __creatures: PBField


	func get_creatures() -> Array[GCreature]:
		return __creatures.value


	func clear_creatures() -> void:
		data[21].state = PB_SERVICE_STATE.UNFILLED
		__creatures.value.clear()


	func add_creatures() -> GCreature:
		var element = GCreature.new()
		__creatures.value.append(element)
		return element


	var __items: PBField


	func get_items() -> Array[GItem]:
		return __items.value


	func clear_items() -> void:
		data[22].state = PB_SERVICE_STATE.UNFILLED
		__items.value.clear()


	func add_items() -> GItem:
		var element = GItem.new()
		__items.value.append(element)
		return element


	var __collectibles: PBField


	func get_collectibles() -> Array[GCollectible]:
		return __collectibles.value


	func clear_collectibles() -> void:
		data[23].state = PB_SERVICE_STATE.UNFILLED
		__collectibles.value.clear()


	func add_collectibles() -> GCollectible:
		var element = GCollectible.new()
		__collectibles.value.append(element)
		return element


	var __projectile_fly_types: PBField


	func get_projectile_fly_types() -> Array[GProjectileFly]:
		return __projectile_fly_types.value


	func clear_projectile_fly_types() -> void:
		data[24].state = PB_SERVICE_STATE.UNFILLED
		__projectile_fly_types.value.clear()


	func add_projectile_fly_types() -> GProjectileFly:
		var element = GProjectileFly.new()
		__projectile_fly_types.value.append(element)
		return element


	var __projectiles: PBField


	func get_projectiles() -> Array[GProjectile]:
		return __projectiles.value


	func clear_projectiles() -> void:
		data[25].state = PB_SERVICE_STATE.UNFILLED
		__projectiles.value.clear()


	func add_projectiles() -> GProjectile:
		var element = GProjectile.new()
		__projectiles.value.append(element)
		return element


	var __interactables: PBField


	func get_interactables() -> Array[GInteractable]:
		return __interactables.value


	func clear_interactables() -> void:
		data[26].state = PB_SERVICE_STATE.UNFILLED
		__interactables.value.clear()


	func add_interactables() -> GInteractable:
		var element = GInteractable.new()
		__interactables.value.append(element)
		return element


	var __masks: PBField


	func get_masks() -> Array[GMask]:
		return __masks.value


	func clear_masks() -> void:
		data[27].state = PB_SERVICE_STATE.UNFILLED
		__masks.value.clear()


	func add_masks() -> GMask:
		var element = GMask.new()
		__masks.value.append(element)
		return element


	var __tags: PBField


	func get_tags() -> Array[GTag]:
		return __tags.value


	func clear_tags() -> void:
		data[28].state = PB_SERVICE_STATE.UNFILLED
		__tags.value.clear()


	func add_tags() -> GTag:
		var element = GTag.new()
		__tags.value.append(element)
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
enum GDamageType {
	DEFAULT,
	SPIKE,
	AOE,
	COUNT,
}

enum GEvadeType {
	BLOCKABLE_IN_ANY_WAY = 3,
	PERFECT_BLOCKABLE = 2,
	JUST_BLOCKABLE = 1,
	ROLLABLE = 4,
	STAMINA_RECOVERING_ROLLABLE = 8,
	COUNT,
}

enum GTeamType {
	ME = 1,
	COMRADES = 2,
	ENEMIES = 4,
	ALL = 7,
	COUNT,
}

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

enum GAbilityType {
	HOOK,
	KAZUHA,
	COUNT,
}

enum GCreatureType {
	INVALID,
	PLAYER,
	MOB_SHOOTER,
	MOB_MAGE,
	MOB_MAGE_TRIPLE,
	MOB_HOMER,
	MOB_HIVER,
	MOB_HIVER_INSIDE,
	MOB_BOMB_INSIDE,
	MOB_JUMPER,
	MOB_BLINKER,
	MOB_BONKER,
	MOB_SPEAR,
	MOB_SUMMONER,
	MOB_SLOWDOWNER,
	COUNT,
}

enum GItemType {
	INVALID,
	GOLD,
	ORE,
	PLANT,
	BONE,
	COUNT,
}

enum GCollectibleType {
	INVALID,
	ORE,
	PLANT,
	BONE,
	COUNT,
}

enum GProjectileFlyType {
	DEFAULT,
	ARC,
	AREA,
	COUNT,
}

enum GProjectileType {
	INVALID,
	ARROW,
	BALL,
	HOOK,
	BOMB_BLOCKABLE,
	BOMB,
	STAR_HIVE_INSIDE,
	STAR_HIVE,
	STAR_BIT,
	HOMING,
	BLINK,
	SUMMON,
	AREA_SLOWDOWN,
	AREA_SPEEDUP,
	AREA_EXPLOSION,
	AREA_KAZUHA,
	COUNT,
}

enum GInteractableType {
	INVALID,
	BARREL_EXPLOSIVE,
	COUNT,
}

enum GMaskType {
	WALLS_FOR_CREATURES,
	CREATURES,
	_3,
	INTERACTABLES,
	WALLS_FOR_PROJECTILES,
	WALLS_FOR_INTERACTABLES,
	COUNT,
}

enum GTagType {
	DASH,
	BLINK,
	HOMING,
	HIVE,
	SUMMON,
	SCALE_MOVEMENT_SPEED,
	HOOK,
	KAZUHA,
	IMPULSE_FROM_CENTER,
	IMPULSE_FROM_OWNER,
	COUNT,
}
