import 'package:part_time_model/part_time_model.dart';
import 'package:test/test.dart';

void main() {
  test('compound interest annual -- 30 years', () {
    final indexFund = Account(
      name: 'Total market index fund',
      value: Dollar.fromCents(100),
    );
    final actions = <Action>[
      InterestAction(
        apy: 0.08,
        interval: SchedulerDuration(SchedulerUnit.year, 1),
        source: indexFund,
      ),
    ];
    const duration = SchedulerDuration(SchedulerUnit.year, 30);
    final scheduler = Scheduler(
      actions: actions,
      duration: duration,
    );

    int runs = 0;
    while (scheduler.runNext()) {
      runs += 1;
    }

    expect(runs, duration.count);
    expect(indexFund.value.value, 10.96);
  });

  test('compound interest monthly -- 30 years', () {
    final indexFund = Account(
      name: 'Total market index fund',
      value: const Dollar.fromCents(100),
    );
    final actions = <Action>[
      InterestAction(
        apy: 0.08,
        interval: SchedulerDuration(SchedulerUnit.month, 1),
        source: indexFund,
      ),
    ];
    const duration = SchedulerDuration(SchedulerUnit.year, 30);
    final scheduler = Scheduler(
      actions: actions,
      duration: duration,
    );

    int runs = 0;
    while (scheduler.runNext()) {
      runs += 1;
    }

    expect(runs, duration.count * 12);
    expect(indexFund.value.value, 11.03);
  });

  test('Consistently investing -- 30 years', () {
    final indexFund = Account(
      name: 'Total market index fund',
      value: const Dollar.fromCents(0),
    );
    final savingsAccount = Account(
      name: 'Savings account',
      value: const Dollar.fromCents(0),
    );
    final actions = <Action>[
      InterestAction(
        apy: 0.08,
        interval: SchedulerDuration(SchedulerUnit.month, 1),
        source: indexFund,
      ),
      IncomeAction(
        name: 'full-time salary',
        account: savingsAccount,
        salary: Dollar(50000),
        postActions: <DependentAction<Dollar, void>>[
          TransferAction(
            name: '10% of salary',
            rate: 0.1,
            source: savingsAccount,
            target: indexFund,
          ),
        ],
      ),
    ];
    const duration = SchedulerDuration(SchedulerUnit.year, 30);
    final scheduler = Scheduler(
      actions: actions,
      duration: duration,
    );

    while (scheduler.runNext()) {}

    expect(indexFund.value.value, 625545.0);
  });
}
