import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:nonce/nonce.dart';

enum AppState { NOT_DOWNLOADED, DOWNLOADING, FINISHED_DOWNLOADING }

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final Uri url = Uri.https('platform.fatsecret.com', 'rest/server.api');
  AppState _state = AppState.NOT_DOWNLOADED;
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String results = '0';
  late List<Food> foods;
  late int pages;
  late int currentPage;

  // unchanging parameters for api call
  final Map<String, dynamic> baseParams = {
    'oauth_consumer_key': '[REDACTED]',
    'oauth_signature_method': 'HMAC-SHA1',
    'oauth_version': '1.0',
    'format': 'json',
    'method': 'foods.search',
    'max_results': '50',
  };

  // make api call
  void foods_search() async {
    // do nothing if text field is empty
    if (_controller.text.isEmpty) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _state = AppState.DOWNLOADING;
    });

    // generate required parameters for api call
    var ms = (DateTime.now()).millisecondsSinceEpoch;
    ms = (ms / 1000).round();
    Map<String, dynamic> parameters = baseParams;
    parameters['oauth_nonce'] = Nonce.generate();
    parameters['oauth_timestamp'] = ms.toString();
    parameters['search_expression'] = _controller.text.replaceAll(' ', '');
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
    final responseBody = jsonDecode(response.body);

    // error handling
    responseBody['error'] != null
        ? results = '0'
        : results = responseBody['foods']['total_results'];

    // set all informational values
    setState(() {
      if (results != '0') {
        // ternary operator handles special case where there is only 1 food on page
        foods = responseBody['foods']['food'] is List
            ? ListFoods(responseBody['foods']['food'])
            : ListFoods([responseBody['foods']['food']]);
        pages = int.parse(results) ~/ 50;
        currentPage = int.parse(responseBody['foods']['page_number']);
      }
      _state = AppState.FINISHED_DOWNLOADING;
    });
  }

  // display list of search results
  Widget foodsList() {
    return Scaffold(
        body: ListView.builder(
            itemCount: foods.length,
            itemBuilder: (context, index) {
              return ListTile(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/get/${foods[index].id}',
                    );
                  },
                  contentPadding: const EdgeInsets.all(8),
                  leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(' ${index + 1 + (currentPage * 50)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold))
                      ]),
                  title: Text('${foods[index].brand} ${foods[index].name}'),
                  subtitle: Text.rich(
                    TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                            text:
                                '${foods[index].calories} calories per ${foods[index].unit}\n',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: '${foods[index].protein}g protein, '),
                        TextSpan(text: '${foods[index].carbs}g carbs, '),
                        TextSpan(text: '${foods[index].fat}g fat'),
                      ],
                    ),
                  ));
            }));
  }

  // shows different screen depending on app state
  Widget searchException() {
    if (_state == AppState.NOT_DOWNLOADED) {
      return const Icon(Icons.search, size: 64, color: Colors.grey);
    } else if (_state == AppState.DOWNLOADING) {
      return const CircularProgressIndicator();
    }
    return const Text('No Results', style: TextStyle(fontSize: 24));
  }

  // app bar search functionality
  Widget _searchTextField() {
    return TextField(
      controller: _controller,
      focusNode: _focus,
      onSubmitted: (String s) {
        setState(() {
          baseParams['page_number'] = '0';
          currentPage = 0;
          foods_search();
        });
      },
      cursorColor: Colors.white,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
      ),
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
        enabledBorder:
            UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
        focusedBorder:
            UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
        hintText: 'Search',
        hintStyle: TextStyle(
          color: Colors.white60,
          fontSize: 20,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: _searchTextField(),
          actions: _controller.text.isEmpty
              ? [
                  IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        setState(() {
                          baseParams['page_number'] = '0';
                          currentPage = 0;
                          foods_search();
                        });
                      })
                ]
              : [
                  IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _controller.clear();
                          _focus.requestFocus();
                        });
                      })
                ]),
      body: Padding(
        padding: const EdgeInsets.all(10),
        // search results page related
        child: Column(children: [
          results != '0'
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                      Column(children: [
                        IconButton(
                          splashRadius: currentPage != 0 ? 18 : 1,
                          icon: const Icon(
                            Icons.arrow_left,
                          ),
                          iconSize: 28,
                          color: currentPage != 0 ? Colors.black : Colors.grey,
                          onPressed: () {
                            if (currentPage != 0) {
                              baseParams['page_number'] =
                                  (currentPage - 1).toString();
                              foods_search();
                            }
                          },
                        )
                      ]),
                      Column(children: [
                        SizedBox(
                            width: 280,
                            child: Center(
                                child: int.parse(results) > 50
                                    ? Text(
                                        'Showing ${currentPage * 50 + 1}-${min((currentPage + 1) * 50, int.parse(results))} results out of $results')
                                    : Text('Showing $results results')))
                      ]),
                      Column(children: [
                        IconButton(
                          splashRadius: currentPage < pages ? 18 : 1,
                          icon: const Icon(
                            Icons.arrow_right,
                          ),
                          iconSize: 28,
                          color:
                              currentPage < pages ? Colors.black : Colors.grey,
                          onPressed: () {
                            if (currentPage < pages) {
                              baseParams['page_number'] =
                                  (currentPage + 1).toString();
                              foods_search();
                            }
                          },
                        )
                      ]),
                    ])
              : const Text(''),
          Expanded(
              child:
                  (_state == AppState.FINISHED_DOWNLOADING) && (results != '0')
                      ? foodsList()
                      : Center(child: searchException()))
        ]),
      ),
    );
  }
}

class Food {
  final String id;
  final String brand;
  final String name;
  final String description;
  late String unit;
  late String calories;
  late String protein;
  late String carbs;
  late String fat;

  Food({
    required this.id,
    required this.brand,
    required this.name,
    required this.description,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    if (json['food_type'] == 'Brand') {
      return Food(
        id: json['food_id'] as String,
        brand: json['brand_name'] as String,
        name: json['food_name'] as String,
        description: json['food_description'] as String,
      );
    } else {
      return Food(
        id: json['food_id'] as String,
        brand: json['food_type'] as String,
        name: json['food_name'] as String,
        description: json['food_description'] as String,
      );
    }
  }
}

// convert search results into list
List<Food> ListFoods(List<dynamic> l) {
  List<Food> parsed = [];
  for (int i = 0; i < l.length; i++) {
    parsed.add(Food.fromJson(l[i]));

    // get nutritional info from food_description
    // number strings formatted to show only 1 decimal
    final str = parsed[i].description;
    final f = NumberFormat("##0.#");
    parsed[i].unit = str
        .substring(str.indexOf('Per ') + 'Per '.length, str.indexOf('-'))
        .trim();
    parsed[i].calories = str
        .substring(str.indexOf('Calories: ') + 'Calories: '.length,
            str.indexOf('kcal'))
        .trim();
    parsed[i].fat = f.format(num.parse(str
        .substring(str.indexOf('Fat: ') + 'Fat: '.length, str.indexOf('g | C'))
        .trim()));
    parsed[i].carbs = f.format(num.parse(str
        .substring(
            str.indexOf('Carbs: ') + 'Carbs: '.length, str.indexOf('g | P'))
        .trim()));
    parsed[i].protein = f.format(num.parse(str
        .substring(
            str.indexOf('Protein: ') + 'Protein: '.length, str.length - 1)
        .trim()));
  }
  return parsed;
}
