import 'package:part_time_model/part_time_model.dart';

void main(List<String> arguments) {
  final indexFund = Account(name: 'Total market index fund', value: Dollar(1));
  final List<Account> accounts = <Account>[
    indexFund,
  ];
  final List<Action> actions = <Action>[
    InterestAction(
      apy: 0.08,
      interval: SchedulerDuration(SchedulerUnit.year, 1),
      source: indexFund,
    ),
  ];
  const duration = SchedulerDuration(SchedulerUnit.year, 30);
  final Scheduler scheduler = Scheduler(
    actions: actions,
    duration: duration,
  );

  while (scheduler.runNext()) {}

  accounts.forEach(print);
}
