import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixabay Image Search',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _imageResults = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1; // Page for infinite scrolling
  final String apiKey = '47302343-d44b2e9ef9100bc10b4e19040';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchRandomImages();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        _fetchRandomImages();
      }
    });
  }

  // Fetch random images from the API
  Future<void> _fetchRandomImages() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('https://pixabay.com/api/?key=$apiKey&image_type=photo&per_page=20&page=$_page');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _page++;
        _imageResults.addAll(data['hits']);
        _hasMore = data['hits'].length == 20;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      print('Failed to load images');
    }
  }

  // Search images based on query
  Future<void> _searchImages(String query) async {
    setState(() {
      _isLoading = true;
      _hasMore = true;
      _imageResults.clear();
      _page = 1;
    });

    final url = Uri.parse('https://pixabay.com/api/?key=$apiKey&q=${Uri.encodeComponent(query)}&image_type=photo&per_page=20&page=$_page');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _imageResults = data['hits'];
        _hasMore = data['hits'].length == 20;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      print('Failed to load images');
    }
  }

  // Display the search dialog
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController searchController = TextEditingController();
        return AlertDialog(
          title: Text('Search Images'),
          content: Container(
            height: 60,
            child: TextField(
              controller: searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search for an image...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 15),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _searchImages(searchController.text);
                FocusScope.of(context).unfocus(); // Close the keyboard after search
              },
              child: Text('Search'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pixabay Image Search'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _isLoading && _imageResults.isEmpty
            ? Center(child: CircularProgressIndicator())
            : GridView.builder(
                controller: _scrollController,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _imageResults.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _imageResults.length) {
                    return Center(child: CircularProgressIndicator());
                  }
                  var image = _imageResults[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenImagePage(
                            imageUrl: image['largeImageURL'],
                            imageName: image['tags'],
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Image.network(
                                image['webformatURL'],
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              image['tags'] ?? 'No description',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;
  final String imageName;

  FullScreenImagePage({required this.imageUrl, required this.imageName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Preview'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: EdgeInsets.all(10),
              color: Colors.black.withOpacity(0.5),
              child: Text(
                imageName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
