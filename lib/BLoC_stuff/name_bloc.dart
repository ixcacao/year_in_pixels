
import 'package:flutter_bloc/flutter_bloc.dart';

class NameEvent {
  final name;
  NameEvent(this.name);
}
class NameState {
  final name;
  NameState(this.name);
}
class NameBloc extends Bloc<NameEvent, NameState>{
  NameBloc() : super(NameState('friend'));

  @override
  Stream<NameState> mapEventToState(NameEvent event) async* {
    yield NameState(event.name);
  }

}