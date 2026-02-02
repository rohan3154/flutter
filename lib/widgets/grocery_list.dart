import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';

import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_items.dart';

class GrosaryList extends StatefulWidget {
  const GrosaryList({super.key});

  @override
  State<GrosaryList> createState() => _GrosaryListState();
}

class _GrosaryListState extends State<GrosaryList> {
  List<GroceryItem> _grosaryItem = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    _loadItem();
    super.initState();
  }

  // load data
  void _loadItem() async {
    final url = Uri.https(
      'flutter-prep-fba21-default-rtdb.firebaseio.com',
      // 'flutter-prep-fba21-default.firebaseio.com',
      'shopping-list.json',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fatch the data. Please try again later';
        });
      }

      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItem = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
              // (catItem) => catItem.value.title == item.value['category'],
              (catItem) => catItem.value.title == item.value['category'],
            )
            .value;
        loadedItem.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }

      setState(() {
        _grosaryItem = loadedItem;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Somethisng went wrong!. Please try again later';
      });
    }
  }

  // remove the data from the app and from the data based
  void _removeItem(GroceryItem item) async {
    int index = _grosaryItem.indexOf(item);

    setState(() {
      _grosaryItem.remove(item);
    });

    final url = Uri.https(
      'flutter-prep-fba21-default-rtdb.firebaseio.com',
      'shopping-list/${item.id}.json',
    );

    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        _grosaryItem.insert(index, item);
      });
    }
  }

  void _addItem() async {
    final newData = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (ctx) => NewItems()));

    if (newData == null) {
      return;
    }

    setState(() {
      _grosaryItem.add(newData);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Center(child: Text("No items add yet"));

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    }

    if (_grosaryItem.isNotEmpty) {
      content = ListView.builder(
        itemCount: _grosaryItem.length,
        itemBuilder: (ctx, index) => Dismissible(
          key: ValueKey(_grosaryItem[index].id),
          onDismissed: (direction) {
            _removeItem(_grosaryItem[index]);
          },
          child: ListTile(
            leading: Container(
              width: 24,
              height: 24,
              color: _grosaryItem[index].category.color,
            ),
            title: Text(_grosaryItem[index].name),
            trailing: Text(_grosaryItem[index].quantity.toString()),
          ),
        ),
      );
    }

    if (_error != null) {
      content = Center(child: Text(_error!));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("your Grocery"),
        actions: [IconButton(onPressed: _addItem, icon: Icon(Icons.add))],
        backgroundColor: Colors.blueGrey,
      ),

      body: content,
    );
  }
}
