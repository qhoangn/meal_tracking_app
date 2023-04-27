import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:nonce/nonce.dart';

import 'package:project/db.dart';

enum AppState { NOT_DOWNLOADED, DOWNLOADING, FINISHED_DOWNLOADING }

class GetScreen extends StatefulWidget {
  final String id;

  const GetScreen(this.id);

  @override
  _GetScreenState createState() => _GetScreenState();
}

class _GetScreenState extends State<GetScreen> {
  final Uri url = Uri.https('platform.fatsecret.com', 'rest/server.api');
  AppState _state = AppState.NOT_DOWNLOADED;
  int _index = 0;
  var servings;
  var brand;
  var name;
  late List<String> descriptions;
  late String dropdownValue;

  //final day = Day()

  // unchanging parameters for api call
  final Map<String, dynamic> baseParams = {
    'oauth_consumer_key': '[REDACTED]',
    'oauth_signature_method': 'HMAC-SHA1',
    'oauth_version': '1.0',
    'format': 'json',
    'method': 'food.get.v2',
  };

  @override
  void initState() {
    super.initState();

    food_get();
  }

  // make api call
  void food_get() async {
    setState(() {
      _state = AppState.DOWNLOADING;
    });

    // generate required parameters for api call
    var ms = (DateTime.now()).millisecondsSinceEpoch;
    ms = (ms / 1000).round();
    Map<String, dynamic> parameters = baseParams;
    parameters['oauth_nonce'] = Nonce.generate();
    parameters['oauth_timestamp'] = ms.toString();
    parameters['food_id'] = widget.id;
    parameters = SplayTreeMap.from(parameters);
    String concatenatedParams = parameters.keys.map((key) {
      return '$key=${parameters[key]}';
    }).join('&');
    var encodedParams = Uri.encodeComponent(concatenatedParams);
    var bytes = utf8.encode(
        'POST&https%3A%2F%2Fplatform.fatsecret.com%2Frest%2Fserver.api&$encodedParams');
    var key = utf8.encode('[REDACTED]&');
    var hmac = Hmac(sha1, key);
    var digest = hmac.convert(bytes);
    parameters['oauth_signature'] = base64Encode(digest.bytes);

    // handle http post response
    final response = await http.post(url, body: parameters);
    final responseBody = jsonDecode(response.body)['food'];

    // set all informational values
    setState(() {
      brand = responseBody['food_type'] == 'Generic'
          ? 'Generic'
          : responseBody['brand_name'];
      name = responseBody['food_name'];
      // ternary operator handles special case where there is only 1 serving size
      servings = responseBody['servings']['serving'] is List
          ? listServings(responseBody['servings']['serving'])
          : listServings([responseBody['servings']['serving']]);
      descriptions = listDescriptions(servings);
      dropdownValue = descriptions.first;
      _state = AppState.FINISHED_DOWNLOADING;
    });
  }

  // display nutritional values of chosen serving
  Widget chart() {
    return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              child: Stack(alignment: Alignment.center, children: [
                Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    children: <TextSpan>[
                      TextSpan(
                          text: servings[_index].calories,
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold)),
                      const TextSpan(
                          text: '\nCal', style: TextStyle(fontSize: 22)),
                    ],
                  ),
                ),
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 60,
                    sections: showingSections(),
                    startDegreeOffset: 180,
                  ),
                ),
              ])),
          Expanded(
              child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: '  ', style: TextStyle(fontSize: 12)),
                const WidgetSpan(
                  child: Icon(
                    Icons.square,
                    size: 24,
                    color: const Color(0xFFFEB13D),
                  ),
                ),
                TextSpan(
                    text:
                        ' ${NumberFormat("##0.#").format(double.parse(servings[_index].protein))}g protein\n',
                    style: const TextStyle(fontSize: 18)),
                const TextSpan(text: '\n  ', style: TextStyle(fontSize: 12)),
                const WidgetSpan(
                  child: Icon(
                    Icons.square,
                    size: 24,
                    color: Color(0xFF2BB9B0),
                  ),
                ),
                TextSpan(
                    text:
                        ' ${NumberFormat("##0.#").format(double.parse(servings[_index].carbs))}g carbs\n',
                    style: const TextStyle(fontSize: 18)),
                const TextSpan(text: '\n  ', style: TextStyle(fontSize: 12)),
                const WidgetSpan(
                  child: Icon(
                    Icons.square,
                    size: 24,
                    color: const Color(0xFFC576E1),
                  ),
                ),
                TextSpan(
                    text:
                        ' ${NumberFormat("##0.#").format(double.parse(servings[_index].fat))}g fat',
                    style: const TextStyle(fontSize: 18)),
              ],
            ),
          ))
        ]);
  }

  // pie chart data formatting
  List<PieChartSectionData> showingSections() {
    return List.generate(3, (i) {
      const radius = 12.0;
      switch (i) {
        case 0:
          return PieChartSectionData(
            color: const Color(0xFFFEB13D),
            value: double.parse(servings[_index].protein),
            radius: radius,
            showTitle: false,
          );
        case 1:
          return PieChartSectionData(
            color: const Color(0xFF2BB9B0),
            value: double.parse(servings[_index].carbs),
            radius: radius,
            showTitle: false,
          );
        case 2:
          return PieChartSectionData(
            color: const Color(0xFFC576E1),
            value: double.parse(servings[_index].fat),
            radius: radius,
            showTitle: false,
          );
        default:
          throw Error();
      }
    });
  }

  Widget _dropdownButton() {
    return DropdownButton<String>(
      isExpanded: true,
      value: dropdownValue,
      icon: const Icon(Icons.arrow_downward),
      elevation: 16,
      style: const TextStyle(color: Colors.deepPurple),
      underline: Container(
        height: 2,
        color: Colors.deepPurpleAccent,
      ),
      onChanged: (String? value) {
        setState(() {
          dropdownValue = value!;
          _index = descriptions.indexOf(value);
        });
      },
      items: descriptions.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Center(child: Text(value)),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Information'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: _state == AppState.FINISHED_DOWNLOADING
            ? Column(
                children: [
                  Center(
                    child: Text('$brand $name',
                        style: const TextStyle(fontSize: 24)),
                  ),
                  _dropdownButton(),
                  Expanded(child: chart()),
                ],
              )
            : const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          const snackBar = SnackBar(
            content: Text('Food added'),
          );
          Map<String, String> info = {
            'id': widget.id,
            'name': '$brand $name',
            'unit': servings[_index].description,
            'calories': servings[_index].calories,
            'protein': servings[_index].protein,
            'carbs': servings[_index].carbs,
            'fat': servings[_index].fat,
          };
          DB().addFood(servings[_index].toMap(info));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          Navigator.pop(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class Serving {
  final String description;
  final String calories;
  final String fat;
  final String carbs;
  final String protein;

  Serving({
    required this.description,
    required this.calories,
    required this.fat,
    required this.carbs,
    required this.protein,
  });

  factory Serving.fromJson(Map<String, dynamic> json) {
    return Serving(
      description: json['serving_description'] as String,
      calories: json['calories'] as String,
      fat: NumberFormat("##0.#").format(num.parse(json['fat'])),
      carbs: NumberFormat("##0.#").format(num.parse(json['carbohydrate'])),
      protein: NumberFormat("##0.#").format(num.parse(json['protein'])),
    );
  }

  Map<String, dynamic> toMap(Map<String, String> info) {
    return {
      'info': info,
      'calories': calories,
      'fat': fat,
      'carbs': carbs,
      'protein': protein,
    };
  }
}

// convert each serving size's nutritional info into list
List<Serving> listServings(List<dynamic> l) {
  List<Serving> parsed = [];
  for (int i = 0; i < l.length; i++) {
    parsed.add(Serving.fromJson(l[i]));
  }
  return parsed;
}

// list of serving descriptions for DropdownButton widget
List<String> listDescriptions(List<Serving> l) {
  List<String> parsed = [];
  for (int i = 0; i < l.length; i++) {
    parsed.add(l[i].description);
  }
  return parsed;
}
