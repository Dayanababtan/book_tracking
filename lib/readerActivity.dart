import 'dart:convert';

import 'package:book_tracking/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailScreen(book: book),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
