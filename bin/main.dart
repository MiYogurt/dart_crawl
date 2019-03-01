import 'package:dart_clawl/dart_clawl.dart' as dart_clawl;
import 'package:args/args.dart';
import 'package:http/http.dart';
import 'dart:io';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import 'dart:convert';
import 'package:path/path.dart';
import 'dart:async';
import 'package:quiver/async.dart';

main(List<String> arguments) async {
  var parser = buildParser();
  var results = parser.parse(arguments);

  if (results.rest.isEmpty || results.options.contains('h')) {
    print("Usage");
    print(parser.usage);
    exit(1);
  }

  var url = results.rest.first;
  List<Map<String, String>> data = await chapter(url);

  await handleChapter(data);
  
  print('Hello world: ${dart_clawl.calculate()}!');
}

Future<Null> handleChapter(List<Map<String, String>> data) async {
  await forEachAsync(data.take(5), (map){
    print("download ${map['title']}");
    return getContent(map['title'], map['link']);
  }, maxTasks: 3);
}

var http_client = Client();

Future<Null> getContent(String title, String link) async {
  var response = await http_client.get(link);
  var document = parse(response.body);
  var content = document.querySelector('#content').text;
  var file = File(absolute('storage/$title.txt'));
  await file.create();
  var str = utf8.decode(content.codeUnits, allowMalformed:true);
  str = str.replaceAll(RegExp(r'�*'), '');
  await file.writeAsString(str);
}

Future<List<Map<String, String>>> chapter(String url) async {
  var http_client = Client();
  var response = await http_client.get(url);
  var document = parse(response.body);
  List<Element> alists = document.querySelectorAll('.box_con #list dd a');
  var uri = Uri.parse(url);
  print(uri.origin);
  await Directory(absolute('storage')).create();
  var file = new File(absolute('storage/chapter.json'));
  await file.create();
  List<Map<String, String>> data = [];

  for (var a in alists) {
    var href = uri.origin + a.attributes['href'];
    data.add({ "title": utf8.decode(a.text.codeUnits), "link": href });
  }

  var str = json.encode(data);
  await file.writeAsString(str);
  return data;
}

ArgParser buildParser(){
  var parse =ArgParser();
  parse.addOption('proxy', abbr: 'p', help: 'Set the network proxy addr', valueHelp: "0.0.0.0:17399");
  parse.addFlag('help', abbr: 'h', help: 'Print the commond line help', defaultsTo: null, negatable: false);
  return parse;
}