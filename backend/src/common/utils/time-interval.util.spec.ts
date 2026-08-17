import { DateTime } from 'luxon';
import { TimeInterval } from './time-interval.util';

describe('TimeInterval', () => {
  const base = DateTime.fromISO('2026-08-20T00:00:00Z');

  it('should subtract non-overlapping interval', () => {
    const a = new TimeInterval(base.set({ hour: 10 }), base.set({ hour: 12 }));
    const b = new TimeInterval(base.set({ hour: 13 }), base.set({ hour: 14 }));
    const result = a.subtract(b);
    expect(result.length).toBe(1);
    expect(result[0].start.hour).toBe(10);
    expect(result[0].end.hour).toBe(12);
  });

  it('should subtract overlapping middle interval', () => {
    const a = new TimeInterval(base.set({ hour: 10 }), base.set({ hour: 15 }));
    const b = new TimeInterval(base.set({ hour: 12 }), base.set({ hour: 13 }));
    const result = a.subtract(b);
    expect(result.length).toBe(2);
    expect(result[0].start.hour).toBe(10);
    expect(result[0].end.hour).toBe(12);
    expect(result[1].start.hour).toBe(13);
    expect(result[1].end.hour).toBe(15);
  });

  it('should subtract overlapping start interval', () => {
    const a = new TimeInterval(base.set({ hour: 10 }), base.set({ hour: 15 }));
    const b = new TimeInterval(base.set({ hour: 9 }), base.set({ hour: 12 }));
    const result = a.subtract(b);
    expect(result.length).toBe(1);
    expect(result[0].start.hour).toBe(12);
    expect(result[0].end.hour).toBe(15);
  });

  it('should subtract overlapping end interval', () => {
    const a = new TimeInterval(base.set({ hour: 10 }), base.set({ hour: 15 }));
    const b = new TimeInterval(base.set({ hour: 14 }), base.set({ hour: 16 }));
    const result = a.subtract(b);
    expect(result.length).toBe(1);
    expect(result[0].start.hour).toBe(10);
    expect(result[0].end.hour).toBe(14);
  });

  it('should return empty if fully covered', () => {
    const a = new TimeInterval(base.set({ hour: 10 }), base.set({ hour: 15 }));
    const b = new TimeInterval(base.set({ hour: 10 }), base.set({ hour: 15 }));
    const result = a.subtract(b);
    expect(result.length).toBe(0);
  });
});
