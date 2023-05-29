import 'package:flutter/material.dart';
import 'package:flutter_map_radius_cluster_example/radius_cluster_layer_page.dart';
import 'package:flutter_map_radius_cluster_example/splay_cluster_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clustering Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const RadiusClusterLayerPage(),
      routes: <String, WidgetBuilder>{
        RadiusClusterLayerPage.route: (context) =>
            const RadiusClusterLayerPage(),
        SplayClusterPage.route: (context) => const SplayClusterPage(),
      },
    );
  }
}

Drawer buildDrawer(BuildContext context, String currentRoute) {
  return Drawer(
    child: ListView(
      children: <Widget>[
        const DrawerHeader(
          child: Center(
            child: Text('Radius Cluster Examples'),
          ),
        ),
        _buildMenuItem(
          context,
          const Text('Basic Example'),
          RadiusClusterLayerPage.route,
          currentRoute,
        ),
        _buildMenuItem(
          context,
          const Text('Splay Cluster Example'),
          SplayClusterPage.route,
          currentRoute,
        ),
      ],
    ),
  );
}

Widget _buildMenuItem(
    BuildContext context, Widget title, String routeName, String currentRoute) {
  var isSelected = routeName == currentRoute;

  return ListTile(
    title: title,
    selected: isSelected,
    onTap: () {
      if (isSelected) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacementNamed(context, routeName);
      }
    },
  );
}
