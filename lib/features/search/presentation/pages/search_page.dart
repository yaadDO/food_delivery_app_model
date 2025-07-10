import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:food_delivery/features/search/domain/entities/search_item.dart';
import 'package:food_delivery/features/search/presentation/cubits/search_cubit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Items'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search items...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (query) => context.read<SearchCubit>().search(query),
            ),
          ),
          Expanded(
            child: BlocBuilder<SearchCubit, SearchState>(
              builder: (context, state) {
                if (state is SearchInitial) {
                  return const Center(child: Text('Start typing to search'));
                }
                if (state is SearchLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is SearchError) {
                  return Center(child: Text('Error: ${state.message}'));
                }
                if (state is SearchLoaded) {
                  return _SearchResults(items: state.results);
                }
                return Container();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final List<SearchItem> items;

  const _SearchResults({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No items found'));
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: _FirebaseImageWidget(imagePath: item.imagePath),
          title: Text(item.name),
          subtitle: Text(item.description),
          trailing: Text('\$${item.price.toStringAsFixed(2)}'),
          onTap: () {
            // Handle item tap
          },
        );
      },
    );
  }
}

class _FirebaseImageWidget extends StatelessWidget {
  final String imagePath;

  const _FirebaseImageWidget({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getImageUrl(imagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            return CachedNetworkImage(
              imageUrl: snapshot.data!,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 50,
                height: 50,
                color: Colors.grey[200],
              ),
              errorWidget: (context, url, error) => Container(
                width: 50,
                height: 50,
                color: Colors.grey[200],
                child: const Icon(Icons.error),
              ),
            );
          }
        }
        return Container(
          width: 50,
          height: 50,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Future<String> _getImageUrl(String imagePath) async {
    return await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
  }
}