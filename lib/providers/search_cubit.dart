import 'package:flutter_bloc/flutter_bloc.dart';

/// Bloc-based search state for features that only need a simple query stream.
class SearchCubit extends Cubit<String> {
  SearchCubit() : super('');

  void updateQuery(String query) => emit(query);

  void clear() => emit('');
}
