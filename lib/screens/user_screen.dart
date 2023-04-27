import 'package:flutter/material.dart';
import 'package:project/db.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({Key? key}) : super(key: key);

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  Widget user() {
    return Column(
      children: [
        Row(
          children: [
            const Text('Age:'),
            SizedBox(
              width: 64,
              child: TextField(
                decoration: InputDecoration(
                  hintText: DB.calc['age'].toString(),
                ),
                onChanged: (String value) => setState(() {
                  DB.calc['age'] = int.parse(value);
                }),
              ),
            )
          ],
        ),
        Row(
          children: [
            const Text('Weight (in lbs):'),
            SizedBox(
                width: 64,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: DB.calc['weight'].toString(),
                  ),
                  onChanged: (String value) => setState(() {
                    DB.calc['weight'] = double.parse(value);
                  }),
                )),
          ],
        ),
        Row(
          children: [
            const Text('Height (inches):'),
            SizedBox(
                width: 64,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: DB.calc['height'].toString(),
                  ),
                  onChanged: (String value) => setState(() {
                    DB.calc['height'] = double.parse(value);
                  }),
                )),
          ],
        ),
        Row(
          children: [
            const Text('Activity level:'),
            SizedBox(
                width: 64,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: DB.calc['activity'].toString(),
                  ),
                  onChanged: (String value) => setState(() {
                    DB.calc['activity'] = double.parse(value);
                  }),
                ))
          ],
        ),
        const SizedBox(
          height: 32,
        ),
        ElevatedButton(
            onPressed: (() {
              setState(() {
                DB.goal['calories'] = (((10 * (DB.calc['weight'] / 2.205)) +
                        (6.25 * (DB.calc['height'] * 2.54)) -
                        (5 * DB.calc['age']) +
                        5) *
                    DB.calc['activity']).toInt();

                DB.goal['protein'] = (DB.goal['calories'] / 4) * 0.3;
                DB.goal['carbs'] = (DB.goal['calories'] / 4) * 0.4;
                DB.goal['fat'] = (DB.goal['calories'] / 9) * 0.3;
              });
            }),
            child: const Text('Calculate')),
        const SizedBox(
          height: 16,
        ),
        Text('calories/day = ${DB.goal['calories']}'),
        Text('protein/day = ${DB.goal['protein']}'),
        Text('carbs/day = ${DB.goal['carbs']}'),
        Text('fat/day = ${DB.goal['fat']}'),
        const SizedBox(
          height: 16,
        ),
        const Text(
            'calories/day = 10 x weight (kg) + 6.25 x height (cm) – 5 x age (years) + 5'),
        const Text('protein/day = calories/day / 4 * 30%'),
        const Text('carbs/day = calories/day / 4 * 40%'),
        const Text('fat/day = calories/day / 9 * 30%'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: const Center(child: Text('Macronutrient Calculator'))),
        body: Padding(
          padding: const EdgeInsets.all(10),
          child: Center(
            child: user(),
          ),
        ));
  }
}
