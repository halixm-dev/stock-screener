import 'dart:io';

void main(List<String> args) {
  if (args.length < 2) {
    print('Usage: dart generate_bloc.dart <feature_name> <bloc_name> [--cubit]');
    print('Example: dart generate_bloc.dart profile user_profile');
    exit(1);
  }

  final featureName = args[0];
  final blocName = args[1]; // e.g., 'user_profile'
  final isCubit = args.length > 2 && args[2] == '--cubit';

  final pascalCaseName = _toPascalCase(blocName); // e.g., 'UserProfile'

  // Mandatory directory structure: presentation/bloc/<bloc_name>/
  final basePath = 'lib/src/features/$featureName/presentation/bloc/$blocName';
  final dir = Directory(basePath);

  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  if (isCubit) {
    _createCubitFiles(basePath, blocName, pascalCaseName);
  } else {
    _createBlocFiles(basePath, blocName, pascalCaseName);
  }

  print('Successfully generated ${isCubit ? 'Cubit' : 'BLoC'} for $pascalCaseName in $basePath');
}

void _createBlocFiles(String basePath, String snakeCase, String pascalCase) {
  // state
  File('$basePath/${snakeCase}_state.dart').writeAsStringSync('''
part of '${snakeCase}_bloc.dart';

sealed class ${pascalCase}State extends Equatable {
  const ${pascalCase}State();

  @override
  List<Object?> get props => [];
}

class ${pascalCase}Initial extends ${pascalCase}State {}
class ${pascalCase}Loading extends ${pascalCase}State {}
class ${pascalCase}Loaded extends ${pascalCase}State {}
class ${pascalCase}Error extends ${pascalCase}State {
  final String message;
  const ${pascalCase}Error(this.message);

  @override
  List<Object?> get props => [message];
}
''');

  // event
  File('$basePath/${snakeCase}_event.dart').writeAsStringSync('''
part of '${snakeCase}_bloc.dart';

sealed class ${pascalCase}Event extends Equatable {
  const ${pascalCase}Event();

  @override
  List<Object?> get props => [];
}

class Load$pascalCase extends ${pascalCase}Event {}
''');

  // bloc
  File('$basePath/${snakeCase}_bloc.dart').writeAsStringSync('''
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part '${snakeCase}_event.dart';
part '${snakeCase}_state.dart';

class ${pascalCase}Bloc extends Bloc<${pascalCase}Event, ${pascalCase}State> {
  ${pascalCase}Bloc() : super(${pascalCase}Initial()) {
    on<Load$pascalCase>(_onLoad$pascalCase);
  }

  Future<void> _onLoad$pascalCase(Load$pascalCase event, Emitter<${pascalCase}State> emit) async {
    emit(${pascalCase}Loading()); // Mandatory loading state
    try {
      // TODO: Implement business logic
      emit(${pascalCase}Loaded());
    } catch (e) {
      emit(${pascalCase}Error(e.toString()));
    }
  }
}
''');
}

void _createCubitFiles(String basePath, String snakeCase, String pascalCase) {
  // state
  File('$basePath/${snakeCase}_state.dart').writeAsStringSync('''
part of '${snakeCase}_cubit.dart';

sealed class ${pascalCase}State extends Equatable {
  const ${pascalCase}State();

  @override
  List<Object?> get props => [];
}

class ${pascalCase}Initial extends ${pascalCase}State {}
class ${pascalCase}Loading extends ${pascalCase}State {}
class ${pascalCase}Loaded extends ${pascalCase}State {}
class ${pascalCase}Error extends ${pascalCase}State {
  final String message;
  const ${pascalCase}Error(this.message);

  @override
  List<Object?> get props => [message];
}
''');

  // cubit
  File('$basePath/${snakeCase}_cubit.dart').writeAsStringSync('''
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part '${snakeCase}_state.dart';

class ${pascalCase}Cubit extends Cubit<${pascalCase}State> {
  ${pascalCase}Cubit() : super(${pascalCase}Initial());

  Future<void> loadData() async {
    emit(${pascalCase}Loading()); // Mandatory loading state
    try {
      // TODO: Implement business logic
      emit(${pascalCase}Loaded());
    } catch (e) {
      emit(${pascalCase}Error(e.toString()));
    }
  }
}
''');
}

String _toPascalCase(String snakeCase) {
  final parts = snakeCase.split('_');
  return parts.map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1)).join('');
}
