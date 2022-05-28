import 'dart:async';
import 'dart:isolate';
import 'dart:io';
import 'dart:math';

import 'countly_worker.dart';

Future<void> main() async {
  // print("main isolate start");
  // create_isolate();
  // print("main isolate end");

  // testUri();
  // testForEachReturn()

  // await testIsolate();
  // testIsolateWorker();

  // for(int i = 0; i < 10; i++) {
  //   print(generateRandomString());
  // }

  // testStreamController();
  // testStreamFromIterable();
  // testStreamFromFuture();
  // testStreamFromPeriodic();

  // testStreamProducerConsumer();

  // testSubString();

  // testTimer();
  testTimerFutureStreamMicrotask();
}

// Future和Timer都在Event队列执行
// Stream在MicroTask对了执行
testTimerFutureStreamMicrotask() {
  var data = [1,2,3,4,5,6,7,8,9];
  print('1');
  Future.delayed(Duration(seconds: 0), () {
    print('future.data=' + data.toString());
  });
  print('2');
  Timer.run(() {
    print('timer.data=' + data.toString());
  });
  print('3');
  // Stream执行的优先级会高于Timer
  Stream.fromIterable(data).listen((event) {
    print('stream.data=$event');
  });
  print('4');
  scheduleMicrotask(() {
    print('scheduleMicrotask1.data=$data');
  });
  scheduleMicrotask(() {
    print('scheduleMicrotask2.data=$data');
  });
  print('5');
}

testTimer() {
  Timer.periodic(const Duration(seconds: 3), (timer) {
    print(DateTime.now().second);
  });
}

testSubString() {
  String eventStr = 'app_key=72ef6149f8ae0d421c8973f71313e049af908074&timestamp=1652085654038&hour=16&dow=1&user_details=%7B%22custom%22%3A%7B%22date%22%3A%2220220509%22%2C%22carrier%22%3A%22%E4%B8%AD%E5%9B%BD%E7%A7%BB%E5%8A%A8%22%2C%22device_model%22%3A%22VOG-AL10%22%2C%22os%22%3A%22Android%22%2C%22density%22%3A%22XXHDPI%22%2C%22os_version%22%3A%2210%22%2C%22fc_device_id%22%3A%22YWzhvk0XWcUDAHUe79zRLZCB%22%2C%22session_id%22%3A%22YWzhvk0XWcUDAHUe79zRLZCB-1652085654029%22%2C%22resolution%22%3A%221080x2265%22%2C%22mac%22%3A%2202%3A00%3A00%3A00%3A00%3A00%22%7D%7D&device_id=07ce338bab754d3a&checksum=5D40521D2A0F9BB6E93A0557A03BEC245F8C1C9E';
  int start = eventStr.indexOf("&device_id=", 0);
  int len = "&device_id=".length;
  print('start=$start, len=$len');
  String deviceId = eventStr.substring(start + len);
  print('deviceId=$deviceId');
}

testStreamProducerConsumer() {
  // List<String> eventData = []; // 模拟event数据
  List<String> spData = []; // 模拟保存到SharedPreference

  StreamController<String> streamController = StreamController();

  // 模拟每1秒生产一份数据
  Timer.periodic(Duration(seconds: 1), (timer) async {
    String event = generateRandomString();
    // 生产event数据，加到stream流里
    streamController.sink.add(event);
    // 模拟保存到SharedPreference
    await Future.delayed(Duration(milliseconds: 100));
    spData.add(event);

    print('producer spData: ' + spData.toString());
  });

  // 模拟消费events数据
  streamController.stream.listen((event) async {
    // 模拟网络请求耗时2秒，然后从spData里删除次调数据
    // Future.delayed(Duration(seconds: 2));
    print('listen((event)');
    await Future.delayed(Duration(seconds: 2));
    spData.remove(event);
    print('after consume spData: ' + spData.toString());
    print('==========================\n');
  });

}

String generateRandomString() {
  final _random = Random();
  const _availableChars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final randomString = List.generate(_random.nextInt(_availableChars.length) + 1,
          (index) => _availableChars[_random.nextInt(_availableChars.length)])
      .join();
  return randomString;
}

// 通过StreamController构建和监听Stream
testStreamController() {
  // 创建Stream
  StreamController<String> controller = StreamController<String>();
  // 向Stream中添加数据
  controller.sink.add("event1");
  controller.sink.add("event2");
  controller.sink.add("event3");
  controller.sink.addError("somethine wrong here!");
  controller.close();
  // 创建Stream监听器
  controller.stream.listen(
      (event) => print(event) ,
      onError: (err) => print(err),
      onDone: () => print('Mission complete!'));
}

testStreamFromIterable() {
  var data = [1,2,3,4,5,6,7,8,9];

  var stream = Stream.fromIterable(data)
      .where((event) => event % 2 == 0)
      .take(2)
      .takeWhile((element) => element < 3)
      .map((event) => event * 3);

  stream.listen((event) {
    print(event);
    print('do something!');
  });
}

testStreamFromFuture() {
  Stream<String> stream = Stream.fromFuture(getData());
  stream.listen((event) {
    print(event);
  }, onDone: () {
    print('stream close!');
  }, onError: (err) {
    print(err);
  });
}

Future<String> getData() async {
  print('正在获取网络数据...');
  // 模拟网络延时3秒后返回数据
  await Future.delayed(Duration(seconds: 3));
  print('获取网络数据成功！');
  return 'get data success!';
}

testStreamFromPeriodic() {
  var stream = Stream<int>.periodic(Duration(seconds: 1), (count) => count * count)
      .take(5);
  stream.forEach((element) {print(element);});
}

testIsolateWorker() {
  var worker = Worker();
  worker.request('发送消息1').then((data) {
    print('子线程处理后的消息:$data');
  });

  Future.delayed(Duration(seconds: 2), () {
    worker.request('发送消息2').then((data) {
      print('子线程处理后的消息:$data');
    });
  });
}

Isolate? thread;

testIsolate() async {
  //创建主线程接收端口，用来接收子线程消息
  ReceivePort mainThreadReceivePort = ReceivePort();
  late SendPort childThreadSendPort;
  //监听子线程消息
  mainThreadReceivePort.listen((data) {
    print('主线程收到来自子线程的消息：$data');
    if (data is SendPort) {
      childThreadSendPort = data;
    }
  });

  // 开启子线程，创建并发Isolate，并传入主线程发送端口
  var params = {"store": 1, "deviceId": 2, 'sendPort': mainThreadReceivePort.sendPort};
  await startThread(params);

  // 向子线程发消息
  await Future.delayed(Duration(seconds: 1), () {
    childThreadSendPort.send('我来自主线程');
  });

  // 向子线程发消息
  await Future.delayed(Duration(seconds: 1), () {
    childThreadSendPort.send('end');
  });
}

startThread(Map<String, dynamic> params) async {
  thread = await Isolate.spawn(run, params);
}

run(Map<String, dynamic> message) {
  ReceivePort threadReceivePort = ReceivePort();
  SendPort mainSendPort = message['sendPort'];
  print('==entryPoint==$message');
  print('子线程开启');
  mainSendPort.send(threadReceivePort.sendPort);
  threadReceivePort.listen((message) {
    print('子线程收到来自主线的消息：$message');
    assert(message is String);
    if (message == 'end') {
      thread?.kill();
      print('子线程结束');
      return;
    }
  });
  return;
}

void testUri() {
  var str = "http:xxx.com/?a=1&b=2&c=3";
  var uri = Uri.parse(str);
  uri.queryParameters.forEach((key, value) {
    print("key=$key, value=$value");
  });
}

void testForEachReturn() {
  bool flag = false;
  Map<String, int> example = {'A': 1, 'B': 2, 'C': 3};
  example.forEach((key, value) {
    if (value == 2) {
      print('value=$value');
      flag = true;
      return;
    }
  });
  print('flag=$flag');
  print("example.length=${example.length}");
}

// 创建一个新的 isolate
create_isolate() async {
  ReceivePort rp = new ReceivePort();
  SendPort port1 = rp.sendPort;

  Isolate newIsolate = await Isolate.spawn(doWork, port1);

  SendPort port2;
  rp.listen((message) {
    print("main isolate message: $message");
    // if (message[0] == 0) {
    //   port2 = message[1];
    // } else {
    //   port2.send([1, "这条信息是 main isolate 发送的"]);
    // }
  });
}

// 处理耗时任务
void doWork(SendPort port1) {
  print("new isolate start");
  ReceivePort rp2 = new ReceivePort();
  SendPort port2 = rp2.sendPort;

  rp2.listen((message) {
    print("doWork message: $message");
  });

// 将新isolate中创建的SendPort发送到主isolate中用于通信
  port1.send([0, port2]);
// 模拟耗时5秒
  sleep(Duration(seconds: 5));
  port1.send([1, "doWork 任务完成"]);

  print("new isolate end");
}
