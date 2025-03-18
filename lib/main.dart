import 'package:flutter/material.dart';
import 'database_helper.dart';

void main() {
  runApp(MaterialApp(home: MasterDetailPage()));
}

class MasterDetailPage extends StatefulWidget {
  @override
  _MasterDetailPageState createState() => _MasterDetailPageState();
}

class _MasterDetailPageState extends State<MasterDetailPage> {
  ToDoItem? selectedItem;
  List<ToDoItem> itemList = [];

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  void loadItems() async {
    itemList = await DatabaseHelper.instance.getItems();
    print("Loaded items: $itemList");
    setState(() {}); // Refresh UI
  }

  void addNewItem(String name, int quantity) async {
    await DatabaseHelper.instance.insert(ToDoItem(name: name, quantity: quantity)); // 👈 No 'id' provided
    loadItems(); // Reload list
  }

  void deleteItem(ToDoItem item) async {
    await DatabaseHelper.instance.delete(item.id!);  // 'id' is now nullable, so using '!'
    setState(() {
      itemList.removeWhere((i) => i.id == item.id);
      selectedItem = null;
    });
  }

  void showAddItemDialog(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    TextEditingController quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add New Item"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: "Item Name")),
              TextField(controller: quantityController, decoration: InputDecoration(labelText: "Quantity"), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && quantityController.text.isNotEmpty) {
                  int quantity = int.tryParse(quantityController.text) ?? 1;
                  addNewItem(nameController.text, quantity);
                  Navigator.pop(context);
                }
              },
              child: Text("Add"),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Shopping List")),
      body: reactiveLayout(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddItemDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget reactiveLayout() {
    var size = MediaQuery.of(context).size;
    bool isTablet = (size.width > size.height) && size.width > 720;

    if (isTablet) {
      return Row(children: [
        Expanded(flex: 1, child: ItemList(itemList, onItemTap: (item) => setState(() => selectedItem = item))),
        Expanded(flex: 2, child: selectedItem != null ? DetailsPage(item: selectedItem!, onDelete: deleteItem, onClose: () => setState(() => selectedItem = null)) : Center(child: Text("Select an item"))),
      ]);
    } else {
      return selectedItem == null
          ? ItemList(itemList, onItemTap: (item) => setState(() => selectedItem = item))
          : DetailsPage(item: selectedItem!, onDelete: deleteItem, onClose: () => setState(() => selectedItem = null));
    }
  }
}

class ItemList extends StatelessWidget {
  final List<ToDoItem> items;
  final Function(ToDoItem) onItemTap;

  ItemList(this.items, {required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    return items.isEmpty
        ? Center(child: Text("No items found", style: TextStyle(fontSize: 18)))
        : ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return ListTile(title: Text(items[index].name), onTap: () => onItemTap(items[index]));
      },
    );
  }
}

class DetailsPage extends StatelessWidget {
  final ToDoItem item;
  final Function(ToDoItem) onDelete;
  final VoidCallback onClose;

  DetailsPage({required this.item, required this.onDelete, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Item Name: ${item.name}", style: TextStyle(fontSize: 20)),
      Text("Quantity: ${item.quantity}"),
      Text("ID: ${item.id}"),
      Row(children: [
        ElevatedButton(onPressed: () => onDelete(item), child: Text("Delete"), style: ElevatedButton.styleFrom(backgroundColor: Colors.red)),
        SizedBox(width: 10),
        ElevatedButton(onPressed: onClose, child: Text("Close"))
      ])
    ]);
  }
}
