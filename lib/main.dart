import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(BookApp());
}

class BookApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book List',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: BookListScreen(),
    );
  }
}

class BookListScreen extends StatefulWidget {
  @override
  _BookListScreenState createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  List books = [];
  bool isOffline = false;

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        isOffline = true;
      });
      return;
    }

    try {
      final response = await http.get(Uri.parse('http://localhost:2505/books'));
      if (response.statusCode == 200) {
        setState(() {
          books = json.decode(response.body);
          isOffline = false;
        });
      } else {
        setState(() {
          isOffline = true;
        });
      }
    } catch (e) {
      setState(() {
        isOffline = true;
      });
    }
  }

  // Method to navigate to ReaderActivityScreen
  void _navigateToReaderActivity() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReaderActivityScreen(),
      ),
    );
  }

  Future<void> _showAddBookDialog() async {
    TextEditingController titleController = TextEditingController();
    TextEditingController authorController = TextEditingController();
    TextEditingController genreController = TextEditingController();
    TextEditingController statusController = TextEditingController();
    TextEditingController reviewCountController = TextEditingController();
    TextEditingController avgRatingController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add a New Book'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: InputDecoration(labelText: 'Title')),
                TextField(controller: authorController, decoration: InputDecoration(labelText: 'Author')),
                TextField(controller: genreController, decoration: InputDecoration(labelText: 'Genre')),
                TextField(controller: statusController, decoration: InputDecoration(labelText: 'Status')),
                TextField(controller: reviewCountController, decoration: InputDecoration(labelText: 'Review Count'),
                  keyboardType: TextInputType.number),
                TextField(controller: avgRatingController, decoration: InputDecoration(labelText: 'Average Rating'),
                  keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _addBook(
                  titleController.text,
                  authorController.text,
                  genreController.text,
                  statusController.text,
                  int.tryParse(reviewCountController.text) ?? 0,
                  double.tryParse(avgRatingController.text) ?? 0.0,
                );
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addBook(String title, String author, String genre, String status, int reviewCount, double avgRating) async {
    var connectivityResult = await Connectivity().checkConnectivity();
    Map<String, dynamic> book = {
      'title': title,
      'author': author,
      'genre': genre,
      'status': status,
      'reviewCount': reviewCount,
      'avgRating': avgRating,
    };

    if (connectivityResult == ConnectivityResult.none) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> offlineBooks = prefs.getStringList('offline_books') ?? [];
      offlineBooks.add(json.encode(book));
      await prefs.setStringList('offline_books', offlineBooks);
      setState(() {
        books.add(book);
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:2505/book'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(book),
      );

      if (response.statusCode == 201) {
        setState(() {
          books.add(json.decode(response.body));
        });
      }
    } catch (e) {
      print('Failed to add book: $e');
    }
  }

  Future<void> _showEditBookDialog(Map<String, dynamic> book) async {
    TextEditingController titleController = TextEditingController(text: book['title']);
    TextEditingController authorController = TextEditingController(text: book['author']);
    TextEditingController genreController = TextEditingController(text: book['genre']);
    TextEditingController statusController = TextEditingController(text: book['status']);
    TextEditingController reviewCountController = TextEditingController(text: book['reviewCount'].toString());
    TextEditingController avgRatingController = TextEditingController(text: book['avgRating'].toString());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Book'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: InputDecoration(labelText: 'Title')),
                TextField(controller: authorController, decoration: InputDecoration(labelText: 'Author')),
                TextField(controller: genreController, decoration: InputDecoration(labelText: 'Genre')),
                TextField(controller: statusController, decoration: InputDecoration(labelText: 'Status')),
                TextField(controller: reviewCountController, decoration: InputDecoration(labelText: 'Review Count'),
                  keyboardType: TextInputType.number),
                TextField(controller: avgRatingController, decoration: InputDecoration(labelText: 'Average Rating'),
                  keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updateBook(
                  book['id'], // Assuming your book has an 'id' field.
                  titleController.text,
                  authorController.text,
                  genreController.text,
                  statusController.text,
                  int.tryParse(reviewCountController.text) ?? 0,
                  double.tryParse(avgRatingController.text) ?? 0.0,
                );
                Navigator.of(context).pop();
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateBook(int bookId, String title, String author, String genre, String status, int reviewCount, double avgRating) async {
    var connectivityResult = await Connectivity().checkConnectivity();
    Map<String, dynamic> updatedBook = {
      'id': bookId, // Send the ID of the book for updating
      'title': title,
      'author': author,
      'genre': genre,
      'status': status,
      'reviewCount': reviewCount,
      'avgRating': avgRating,
    };

    if (connectivityResult == ConnectivityResult.none) {
      // Handle offline update, e.g., store in local storage
      return;
    }

    try {
      final response = await http.put(
        Uri.parse('http://localhost:2505/book'), // Use the endpoint for updating book
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatedBook),
      );

      if (response.statusCode == 200) {
        setState(() {
          // Update the book locally in the list
          int index = books.indexWhere((b) => b['id'] == bookId);
          if (index != -1) {
            books[index] = updatedBook;
          }
        });
      } else {
        print('Failed to update book: ${response.body}');
      }
    } catch (e) {
      print('Error while updating book: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book List')),
      body: isOffline
          ? Center(child: Text('No internet connection'))
          : books.isEmpty
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return ListTile(
                      title: Text(book['title']),
                      subtitle: Text('Author: ${book['author']}'),
                      trailing: Text('${book['avgRating']} ⭐'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookDetailScreen(book: book),
                          ),
                        );
                      },
                      onLongPress: () {
                        _showEditBookDialog(book);
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBookDialog,
        child: Icon(Icons.add),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              title: Text('Reader Activity'),
              onTap: _navigateToReaderActivity,
            ),
          ],
        ),
      ),
    );
  }
}

// New screen for displaying books where status is 'reading'
class ReaderActivityScreen extends StatefulWidget {
  @override
  _ReaderActivityScreenState createState() => _ReaderActivityScreenState();
}

class _ReaderActivityScreenState extends State<ReaderActivityScreen> {
  List books = [];

  @override
  void initState() {
    super.initState();
    _fetchReadingBooks();
  }

  Future<void> _fetchReadingBooks() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:2505/books'));
      if (response.statusCode == 200) {
        List allBooks = json.decode(response.body);
        setState(() {
          books = allBooks.where((book) => book['status'] == 'reading').toList();
        });
      } else {
        print('Failed to fetch books');
      }
    } catch (e) {
      print('Error while fetching books: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reading Books')),
      body: books.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return ListTile(
                  title: Text(book['title']),
                  subtitle: Text('Author: ${book['author']}'),
                  trailing: Text('${book['avgRating']} ⭐'),
                );
              },
            ),
    );
  }
}

class BookDetailScreen extends StatelessWidget {
  final Map<String, dynamic> book;

  BookDetailScreen({required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(book['title'])),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Author: ${book['author']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Genre: ${book['genre']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Status: ${book['status']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Reviews: ${book['reviewCount']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Average Rating: ${book['avgRating']} ⭐', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
