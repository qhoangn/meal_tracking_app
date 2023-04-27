import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:project/db.dart';

enum AppState { NOT_DOWNLOADED, DOWNLOADING, FINISHED_DOWNLOADING }

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Widget chartCalories() {
    return Stack(alignment: Alignment.center, children: [
      Text.rich(
        textAlign: TextAlign.center,
        TextSpan(
          children: <TextSpan>[
            TextSpan(
                text: (DB.goal['calories'] - DB.calories).abs().toString(),
                style: const TextStyle(
                    color: Color(0xFFE0E0E0),
                    fontSize: 48,
                    fontWeight: FontWeight.bold)),
            TextSpan(
                text: DB.calories < DB.goal['calories']
                    ? '\nremaining'
                    : '\nsurplus',
                style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 24)),
          ],
        ),
      ),
      PieChart(
        PieChartData(
          startDegreeOffset: 270,
          sectionsSpace: 2,
          centerSpaceRadius: 128,
          sections: List.generate(2, (i) {
            const radius = 16.0;
            switch (i) {
              case 0:
                return PieChartSectionData(
                  color: DB.calories < DB.goal['calories']
                      ? const Color(0xFF71BAFF)
                      : Colors.red,
                  value: DB.calories < DB.goal['calories']
                      ? DB.calories.toDouble()
                      : (DB.calories - DB.goal['calories']).toDouble(),
                  radius: radius,
                  showTitle: false,
                );
              case 1:
                return PieChartSectionData(
                  color: DB.calories < DB.goal['calories']
                      ? const Color(0xFF3B3D46)
                      : const Color(0xFF71BAFF),
                  value: DB.calories < DB.goal['calories']
                      ? (DB.goal['calories'] - DB.calories).toDouble()
                      : (DB.goal['calories'] - (DB.calories - DB.goal['calories']))
                          .toDouble(),
                  radius: radius,
                  showTitle: false,
                );
              default:
                throw Error();
            }
          }),
        ),
        swapAnimationDuration: const Duration(milliseconds: 1000),
        swapAnimationCurve: Curves.ease,
      ),
    ]);
  }

  Widget chartMacros(String type) {
    double value = 0;
    Color c = Colors.redAccent;
    switch (type) {
      case 'protein':
        value = DB.protein;
        c = const Color(0xFFFEB13D);
        break;
      case 'carbs':
        value = DB.carbs;
        c = const Color(0xFF2BB9B0);
        break;
      case 'fat':
        value = DB.fat;
        c = const Color(0xFFC576E1);
        break;
    }

    return Stack(alignment: Alignment.center, children: [
      Text.rich(
        textAlign: TextAlign.center,
        TextSpan(
          children: <TextSpan>[
            TextSpan(
                text:
                    '${double.parse(NumberFormat("##0.#").format(DB.goal[type] - value)).abs()}g',
                style: const TextStyle(
                    color: Color(0xFFE0E0E0),
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            TextSpan(
                text: value < DB.goal[type] ? '\nremaining' : '\nsurplus',
                style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 10)),
          ],
        ),
      ),
      PieChart(
        PieChartData(
          startDegreeOffset: 270,
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: List.generate(2, (i) {
            const radius = 6.0;
            switch (i) {
              case 0:
                return PieChartSectionData(
                  color: value < DB.goal[type] ? c : Colors.red,
                  value: value < DB.goal[type]
                      ? value.toDouble()
                      : (value - DB.goal[type]).toDouble(),
                  radius: radius,
                  showTitle: false,
                );
              case 1:
                return PieChartSectionData(
                  color: value < DB.goal[type] ? const Color(0xFF3B3D46) : c,
                  value: value < DB.goal[type]
                      ? (DB.goal[type] - value).toDouble()
                      : (DB.goal[type] - (value - DB.goal[type])).toDouble(),
                  radius: radius,
                  showTitle: false,
                );
              default:
                throw Error();
            }
          }),
        ),
        swapAnimationDuration: const Duration(milliseconds: 1000),
        swapAnimationCurve: Curves.ease,
      ),
    ]);
  }

  Widget charts() {
    var w = MediaQuery.of(context).size.width;
    return Consumer<DB>(
        builder: (_, __, ___) => Column(children: [
              //charts for calories / macronutrients
              Container(
                  width: w,
                  height: w + 8,
                  decoration: const BoxDecoration(
                    color: Color(0xff252833),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    boxShadow: [
                      BoxShadow(
                        offset: Offset(0, 0),
                        blurRadius: 2,
                        spreadRadius: 2,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                  child: Column(children: [
                    const SizedBox(height: 20),
                    const Text('Calories',
                        style: TextStyle(
                            color: Color(0xFFE0E0E0),
                            fontSize: 32,
                            fontWeight: FontWeight.bold)),
                    Expanded(child: chartCalories()),
                    const SizedBox(height: 4),
                  ])),
              const SizedBox(height: 10),
              // show foods added for day
              Container(
                  width: w,
                  height: w / 3 + 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFF252833),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    boxShadow: [
                      BoxShadow(
                        offset: Offset(0, 0),
                        blurRadius: 2,
                        spreadRadius: 2,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                            width: w / 3 - 20,
                            child: Column(children: [
                              const SizedBox(height: 8),
                              Expanded(child: chartMacros('protein')),
                              const Text('Protein',
                                  style: TextStyle(
                                      color: Color(0xFFE0E0E0),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 14),
                            ])),
                        Container(
                            width: w / 3 - 20,
                            child: Column(children: [
                              const SizedBox(height: 8),
                              Expanded(child: chartMacros('carbs')),
                              const Text('Carbs',
                                  style: TextStyle(
                                      color: Color(0xFFE0E0E0),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 14),
                            ])),
                        Container(
                            width: w / 3 - 20,
                            child: Column(children: [
                              const SizedBox(height: 8),
                              Expanded(child: chartMacros('fat')),
                              const Text('Fat',
                                  style: TextStyle(
                                      color: Color(0xFFE0E0E0),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 14),
                            ])),
                      ]))
            ]));
  }

  Widget home() {
    return ListView.separated(
      itemCount: DB.foods == null ? 1 : DB.foods.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(children: [
            charts(),
            const SizedBox(height: 16),
            const Text('Food Log',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
          ]);
        }
        index -= 1;
        var row = DB.foods[index];
        return Ink(
            child: ListTile(
                leading: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(' ${index + 1}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold))
                    ]),
                title: Text(row['name']),
                subtitle: Text.rich(
                  TextSpan(children: <TextSpan>[
                    TextSpan(
                        text:
                            '${row['calories']} calories per ${row['unit']}\n',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '${row['protein']}g protein, '),
                    TextSpan(text: '${row['carbs']}g carbs, '),
                    TextSpan(text: '${row['fat']}g fat'),
                  ]),
                )));
      },
      separatorBuilder: (context, index) {
        return const Divider(
          height: 8,
        );
      },
    );
  }

  // app bar title widget with selectable date button
  Widget title() {
    DateTime d = DateTime.parse(DB.id.toString());

    String suffix;
    switch (int.parse(DateFormat('d').format(d)) % 10) {
      case 1:
        suffix = 'st';
        break;
      case 2:
        suffix = 'nd';
        break;
      case 3:
        suffix = 'rd';
        break;
      default:
        suffix = 'th';
    }

    return Consumer<DB>(
        builder: (_, __, ___) => Row(children: [
              Expanded(
                child: OutlinedButton(
                    onPressed: () async {
                      final DateTime d = DateTime.parse(DB.id.toString());
                      final DateTime? picked = await showDatePicker(
                        context: super.context,
                        initialDate: d,
                        firstDate: DateTime(1999),
                        lastDate: DateTime(2099),
                      );
                      if (picked != null && picked != d) {
                        setState(() {
                          DB().setDay(
                              int.parse(DateFormat('yyyyMMdd').format(picked)));
                        });
                      }
                    },
                    child: Text(DateFormat('EEEE, MMMM d').format(d) + suffix,
                        style: const TextStyle(
                            fontSize: 18, color: Colors.white))),
              )
            ]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_left),
            iconSize: 36,
            onPressed: () {
              setState(() {
                DB().setDay(DB.id - 1);
              });
            }),
        title: title(),
        actions: [
          IconButton(
              icon: const Icon(Icons.arrow_right),
              iconSize: 36,
              onPressed: () {
                setState(() {
                  DB().setDay(DB.id + 1);
                });
              })
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Center(
            child: Column(children: [
          Expanded(child: home()),
          SizedBox(height: 24),
        ])),
      ),
    );
  }
}
