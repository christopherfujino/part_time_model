import 'package:part_time_model/part_time_model.dart';
import 'package:test/test.dart';

void main() {
  test(r'time to $1M from investing $100/month', () {
    final ctx = Context();
    final invest = Invest<int>(
      ctx,
      interval: SchedulerDuration(months: 1),
      pushHandlers: [],
      amount: 100 * 100, // $100
    );

    // Investment account
    final investmentAccumulator = Accumulator<int>(
      pushHandlerRegistrars: [],
      pushHandlers: [],
      pullHandlerRegistrars: [],
      reducer: (acc, cur) => acc + cur,
      isDone: (int value) => value >= (1000000 * 100), // $1M
      initialValue: 0,
    );

    // Sum of investment capital
    final investmentCapitalAccumulator = Accumulator<int>(
      pushHandlerRegistrars: [],
      pushHandlers: [],
      pullHandlerRegistrars: [],
      reducer: (acc, cur) => acc + cur,
      initialValue: 0,
      isDone: (_) => false,
    );

    // Interest
    final interest = Interest(
      ctx,
      rate: 0.1,
      pushHandlers: [],
    );
    int lastBalanceCents = 0;
    int lastCapitalCents = 0;
    final investmentPlotter = Plotter(
      label: 'Investment balance',
      callback: (cents) {
        lastBalanceCents = cents;
        return false;
      },
      pushHandlerRegistrars: [],
    );
    final capitalPlotter = Plotter(
      label: 'Investment capital',
      callback: (cents) {
        lastCapitalCents = cents;
        return false;
      },
      pushHandlerRegistrars: [],
    );

    connectPush<int>(PushPipe('a'), invest, investmentAccumulator);
    connectPush<int>(PushPipe('b'), invest, investmentCapitalAccumulator);
    connectPush<int>(PushPipe('c'), investmentAccumulator, investmentPlotter);
    connectPush<int>(PushPipe('d'), investmentCapitalAccumulator, capitalPlotter);
    connectPull<int>(PullPipe(), interest, investmentCapitalAccumulator);

    while (true) {
      if (ctx.scheduler.tick()) {
        break;
      }
    }
    expect(ctx.scheduler.months, 44.5 * 12);
    // > $1M
    expect(lastBalanceCents, greaterThanOrEqualTo(1000000 * 100));
    expect(lastCapitalCents, 44.5 * 12 * 10000);
  });
}
