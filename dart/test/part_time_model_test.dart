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
      pushers: [
        pipe1.push,
        pushToInvestmentCapitalAccumulator.push,
      ],
      amount: 100 * 100, // $100
    );
    // Plot from Investment Account
    final plotPullFromInvestment = PullPipe<int>();
    final plotPullFromInvestmentCapital = PullPipe<int>();
    // Interest from Investment Account
    final pipe3 = PullPipe<int>();
    // Interest to Investment Account
    final pipe4 = PushPipe<int>();

    // Investment account
    Accumulator(
      registerPushHandlers: [
        pipe1.registerPushHandler,
        pipe4.registerPushHandler,
      ],
      registerPullHandlers: [
        plotPullFromInvestment.registerPullHandler,
        pipe3.registerPullHandler,
      ],
      reducer: (acc, cur) => acc + cur,
      initialValue: 0,
    );

    // Sum of investment capital
    Accumulator(
      registerPushHandlers: [
        pushToInvestmentCapitalAccumulator.registerPushHandler
      ],
      registerPullHandlers: [plotPullFromInvestmentCapital.registerPullHandler],
      reducer: (acc, cur) => acc + cur,
      initialValue: 0,
    );

    // Interest
    Interest(
      ctx,
      rate: 0.1,
      pull: pipe3.pull,
      pushers: [pipe4.push],
    );
    int lastBalanceCents = 0;
    int lastCapitalCents = 0;
    int lastYears = 0;
    Plotter(
      ctx,
      callback: (_, years, cents) {
        lastBalanceCents = cents;
        lastYears = years;
      },
      pull: plotPullFromInvestment.pull,
      isDone: (int x) => x >= 1000000 * 100, // $1M
      label: 'Investment balance',
      interval: SchedulerDuration(years: 1),
    );
    Plotter(
      ctx,
      pull: plotPullFromInvestmentCapital.pull,
      isDone: (int _) => false,
      label: 'Investment capital',
      interval: SchedulerDuration(years: 1),
      callback: (_, years, cents) {
        lastCapitalCents = cents;
        lastYears = years;
      }
    );
    while (true) {
      if (ctx.scheduler.tick()) {
        break;
      }
    }
    expect(lastYears, 45);
    // > $1M
    expect(lastBalanceCents, greaterThanOrEqualTo(1000000 * 100));
    expect(lastCapitalCents, 45 * 12 * 10000);
  });
}
