/*
 * MIT License
 * Copyright (c) 2021 Hyeonki Hong <hhk7734@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'bindings.g.dart';
import 'common.dart';
import 'chip.dart';

enum LineRequestType {
  NONE,
  DIRECTION_AS_IS,
  DIRECTION_INPUT,
  DIRECTION_OUTPUT,
  EVENT_FALLING_EDGE,
  EVENT_RISING_EDGE,
  EVENT_BOTH_EDGES
}

class LineRequestFlag {
  static const FLAG_ACTIVE_LOW = GPIOD_LINE_REQUEST_FLAG_OPEN_DRAIN;
  static const FLAG_OPEN_SOURCE = GPIOD_LINE_REQUEST_FLAG_OPEN_SOURCE;
  static const FLAG_OPEN_DRAIN = GPIOD_LINE_REQUEST_FLAG_ACTIVE_LOW;
  // static const FLAG_BIAS_DISABLE = GPIOD_LINE_REQUEST_FLAG_BIAS_DISABLE;
  // static const FLAG_BIAS_PULL_DOWN = GPIOD_LINE_REQUEST_FLAG_BIAS_PULL_DOWN;
  // static const FLAG_BIAS_PULL_UP = GPIOD_LINE_REQUEST_FLAG_BIAS_PULL_UP;
}

const _reqtypeMapping = {
  LineRequestType.DIRECTION_AS_IS: GPIOD_LINE_REQUEST_DIRECTION_AS_IS,
  LineRequestType.DIRECTION_INPUT: GPIOD_LINE_REQUEST_DIRECTION_INPUT,
  LineRequestType.DIRECTION_OUTPUT: GPIOD_LINE_REQUEST_DIRECTION_OUTPUT,
  LineRequestType.EVENT_BOTH_EDGES: GPIOD_LINE_REQUEST_EVENT_BOTH_EDGES,
  LineRequestType.EVENT_FALLING_EDGE: GPIOD_LINE_REQUEST_EVENT_FALLING_EDGE,
  LineRequestType.EVENT_RISING_EDGE: GPIOD_LINE_REQUEST_EVENT_RISING_EDGE,
};

class LineRequest {
  LineRequest({
    this.consummer = '',
    this.requestType = LineRequestType.NONE,
    this.flag = 0,
  });

  String consummer;
  LineRequestType requestType;
  int flag;
}

class Line {
  Pointer<gpiod_line> _line;
  Chip _chip;
  final _native = libGpiod;

  Line(Pointer<gpiod_line> line, Chip chip)
      : _line = line,
        _chip = chip;

  int get offset => _native.gpiod_line_offset(_throw_if_noref_and_get_line);

  String get name => _native
      .gpiod_line_name(_throw_if_noref_and_get_line)
      .toStringAfterNullCheck();

  String get consumer => _native
      .gpiod_line_consumer(_throw_if_noref_and_get_line)
      .toStringAfterNullCheck();

  int get direction =>
      _native.gpiod_line_direction(_throw_if_noref_and_get_line);

  int get activeState =>
      _native.gpiod_line_active_state(_throw_if_noref_and_get_line);

  bool isUsed() =>
      _native.gpiod_line_is_used(_throw_if_noref_and_get_line) != 0;

  bool isOpenDrain() =>
      _native.gpiod_line_is_open_drain(_throw_if_noref_and_get_line) != 0;

  bool isOpenSource() =>
      _native.gpiod_line_is_open_source(_throw_if_noref_and_get_line) != 0;

  /// Requests this line.
  ///
  /// * `config`: see [LineRequest].
  /// * `defaultValue`: Default value - only matters for OUTPUT direction.
  ///
  /// ```dart
  ///     final config = LineRequest()
  ///     config.consumer = "flutter";
  ///     config.requestType = LineRequestType.DIRECTION_OUTPUT;
  ///
  ///     line.request(config);
  /// ```
  void request(LineRequest config, [int defaultValue = 0]) {
    final lineConfig = calloc.allocate<gpiod_line_request_config>(
        sizeOf<gpiod_line_request_config>());

    lineConfig.ref.consumer = config.consummer.toInt8Pointer();
    if (config.requestType == LineRequestType.NONE) {
      throw 'GPIOD: Line: LineRequestType should not be NONE';
    } else {
      lineConfig.ref.request_type = _reqtypeMapping[config.requestType]!;
    }
    lineConfig.ref.flags = 0;

    final rv = _native.gpiod_line_request(
        _throw_if_noref_and_get_line, lineConfig, defaultValue);
    if (rv != 0) {
      throw 'GPIOD: Line: error requesting GPIO line';
    }

    calloc.free(lineConfig);
  }

  void release() {
    _native.gpiod_line_release(_throw_if_noref_and_get_line);
  }

  int getValue() => _native.gpiod_line_get_value(_throw_if_noref_and_get_line);

  void setValue(int value) =>
      _native.gpiod_line_set_value(_throw_if_noref_and_get_line, value);

  Pointer<gpiod_line> get _throw_if_noref_and_get_line => _line != nullptr
      ? _line
      : throw 'GPIOD: Line: object not associated with an open GPIO chip';
}
