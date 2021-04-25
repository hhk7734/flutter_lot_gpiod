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
import 'line.dart';

class Chip {
  String device = '';
  Pointer<gpiod_chip> _chip = nullptr;
  final _native = libGpiod;

  Chip(this.device);

  void init() {
    dispose();

    _chip = _native.gpiod_chip_open_lookup(device.toInt8Pointer());
    if (_chip == nullptr) {
      throw 'GPIOD: Chip: failed to open $device';
    }
    device = '/dev/$name';
  }

  String get name => _native
      .gpiod_chip_name(_throw_if_noref_and_get_chip)
      .toStringAfterNullCheck();

  String get label => _native
      .gpiod_chip_label(_throw_if_noref_and_get_chip)
      .toStringAfterNullCheck();

  int get numLines =>
      _native.gpiod_chip_num_lines(_throw_if_noref_and_get_chip);

  Line getLine(int offset) {
    final line =
        _native.gpiod_chip_get_line(_throw_if_noref_and_get_chip, offset);
    if (line == nullptr) {
      throw 'GPIOD: Chip: error getting GPIO line from chip';
    }
    return Line(line, this);
  }

  Line findLine(String name) {
    final line = _native.gpiod_chip_find_line(
        _throw_if_noref_and_get_chip, name.toInt8Pointer());
    if (line == nullptr) {
      throw 'GPIOD: Chip: error looking up GPIO line by name';
    }
    return Line(line, this);
  }

  void dispose() {
    if (_chip != nullptr) {
      print('dispose');
      _native.gpiod_chip_close(_chip);
      _chip = nullptr;
    }
  }

  Pointer<gpiod_chip> get _throw_if_noref_and_get_chip => _chip != nullptr
      ? _chip
      : throw 'GPIOD: Chip: object not associated with an open GPIO chip';
}
