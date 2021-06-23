import 'package:flutter_bloc/flutter_bloc.dart';

class UpdateSubscriptionEvent {
  final bool isPremium;
  UpdateSubscriptionEvent(this.isPremium);
}

class UpdateSubscriptionState {
  final bool isPremium;
  UpdateSubscriptionState(this.isPremium);
}



class UpdateSubscriptionBloc extends Bloc<UpdateSubscriptionEvent, UpdateSubscriptionState> {
  UpdateSubscriptionBloc() : super(UpdateSubscriptionState(null));

  @override
  Stream<UpdateSubscriptionState> mapEventToState(UpdateSubscriptionEvent event) async* {
    print('SUBSCRIPTION BLOC updated! User has premium is ${event.isPremium}');
    yield UpdateSubscriptionState(event.isPremium);
  }
}