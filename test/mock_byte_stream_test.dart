import 'dart:convert';

import 'package:mock_byte_stream/mock_byte_stream.dart';
import 'package:test/test.dart';

// ignore: prefer_single_quotes
var bytes = utf8.encode("""BSD 3-Clause License

Copyright (c) 2021, Mgenware (Liu YuanYuan)
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.""");

Future<List<int>> toList(Stream<List<int>> stream) async {
  List<int> list = [];
  await for (var bytes in stream) {
    list.addAll(bytes);
  }
  return list;
}

Future<List<int>> toListMuted(Stream<List<int>> stream) async {
  List<int> list = [];
  try {
    await for (var bytes in stream) {
      list.addAll(bytes);
    }
  } catch (_) {}
  return list;
}

void main() {
  test('Defaults', () async {
    var mbs = MockByteStream(bytes, 4);
    expect(await toList(mbs.stream()), bytes);
  });

  test('Length larger than byte length', () async {
    var mbs = MockByteStream([1, 2, 3, 4], 20);
    expect(await toList(mbs.stream()), [1, 2, 3, 4]);
  });

  test('Length larger than byte length (error)', () {
    var mbs = MockByteStream([1, 2, 3, 4], 20, hasError: true);
    expect(toList(mbs.stream()), throwsException);
  });

  test('Delay', () async {
    var mbs = MockByteStream(bytes, 100,
        minDelay: Duration(milliseconds: 20),
        maxDelay: Duration(microseconds: 100));
    expect(await toList(mbs.stream()), bytes);
  });

  test('Only minDelay', () async {
    var mbs = MockByteStream(bytes, 100, minDelay: Duration(milliseconds: 50));
    expect(await toList(mbs.stream()), bytes);
  });

  test('Only maxDelay', () async {
    var mbs = MockByteStream(bytes, 100, maxDelay: Duration(milliseconds: 50));
    expect(await toList(mbs.stream()), bytes);
  });

  test('Error', () {
    var mbs = MockByteStream(bytes, 100,
        maxDelay: Duration(milliseconds: 50), hasError: true);
    expect(toList(mbs.stream()), throwsException);
  });

  test('ErrorPosition.start', () async {
    var mbs = MockByteStream(bytes, 100,
        maxDelay: Duration(milliseconds: 50),
        hasError: true,
        errorPosition: ErrorPosition.start);
    var list = await toListMuted(mbs.stream());
    expect(list.isEmpty, true);
  });

  test('ErrorPosition.middle', () async {
    var mbs = MockByteStream(bytes, 100,
        maxDelay: Duration(milliseconds: 50),
        hasError: true,
        errorPosition: ErrorPosition.middle);
    var list = await toListMuted(mbs.stream());
    expect(list.isNotEmpty, true);
    expect(list.length != bytes.length, true);
  });

  test('ErrorPosition.end', () async {
    var mbs = MockByteStream(bytes, 100,
        maxDelay: Duration(milliseconds: 50),
        hasError: true,
        errorPosition: ErrorPosition.end);
    var list = await toListMuted(mbs.stream());
    expect(list.length, bytes.length);
  });
}
