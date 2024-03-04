import 'package:part_time_model/part_time_model.dart';
import 'package:test/test.dart';

void main() {
  test(r'time to $1M from investing $100/month', () {
    final ctx = Context();
    final pipe1 = PushPipe<int>();
    final pushToInvestmentCapitalAccumulator = PushPipe<int>();
    Invest(
      ctx,
      interval: SchedulerDuration(months: 1),
      pushHandlers: [
        pipe1.push,
        pushToInvestmentCapitalAccumulator.push,
      ],
      amount: 100 * 100, // $100
    );
    // Plot from Investment Account
    final pushFromInvestmentToPlotter = PushPipe<int>();
    final pushFromCapitalToPlotter = PushPipe<int>();
    // Interest from Investment Account
    final pipe3 = PullPipe<int>();
    // Interest to Investment Account
    final pipe4 = PushPipe<int>();

    // Investment account
    Accumulator<int>(
      pushHandlerRegistrars: [
        pipe1.registerHandler,
        pipe4.registerHandler,
      ],
      pushHandlers: [pushFromInvestmentToPlotter.push],
      registerPullHandlers: [pipe3.registerHandler],
      reducer: (acc, cur) => acc + cur,
      isDone: (int value) => value >= (1000000 * 100), // $1M
      initialValue: 0,
    );

    // Sum of investment capital
    Accumulator<int>(
      pushHandlerRegistrars: [
        pushToInvestmentCapitalAccumulator.registerHandler
      ],
      pushHandlers: [pushFromCapitalToPlotter.push],
      registerPullHandlers: [],
      reducer: (acc, cur) => acc + cur,
      initialValue: 0,
      isDone: (_) => false,
    );

    // Interest
    Interest(
      ctx,
      rate: 0.1,
      pull: pipe3.pull,
      pushHandlers: [pipe4.push],
    );
    int lastBalanceCents = 0;
    int lastCapitalCents = 0;
    Plotter(
      label: 'Investment balance',
      callback: (cents) {
        lastBalanceCents = cents;
        return false;
      },
      pushHandlerRegistrars: [pushFromInvestmentToPlotter.registerHandler],
    );
    Plotter(
      label: 'Investment capital',
      callback: (cents) {
        lastCapitalCents = cents;
        return false;
      },
      pushHandlerRegistrars: [pushFromCapitalToPlotter.registerHandler],
    );
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
