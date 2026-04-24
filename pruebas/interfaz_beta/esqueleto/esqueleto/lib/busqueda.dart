import 'package:flutter/material.dart';
import 'layout/barr_busq.dart';
import 'layout/routes_list.dart';

class Busqueda extends StatefulWidget {
  const Busqueda({super.key});

  @override
  State<Busqueda> createState() => _BusquedaState();
}

class _BusquedaState extends State<Busqueda> {
  final TextEditingController _controller = TextEditingController();
  String query = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SearchBarWithBack(
              controller: _controller,
              onChanged: (value) => setState(() => query = value),
            ),
            const Divider(),
            RoutesList(query: query),
          ],
        ),
      ),
    );
  }
}
