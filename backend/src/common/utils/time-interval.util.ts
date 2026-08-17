import { DateTime } from 'luxon';

export class TimeInterval {
  constructor(
    public readonly start: DateTime,
    public readonly end: DateTime,
  ) {
    if (start >= end) {
      throw new Error('Start must be before end');
    }
  }

  overlaps(other: TimeInterval): boolean {
    return this.start < other.end && other.start < this.end;
  }

  contains(other: TimeInterval): boolean {
    return this.start <= other.start && other.end <= this.end;
  }

  /**
   * Subtracts an interval from this one.
   * Returns an array of remaining intervals.
   */
  subtract(other: TimeInterval): TimeInterval[] {
    if (!this.overlaps(other)) {
      return [this];
    }

    const result: TimeInterval[] = [];

    // Part before the other interval
    if (this.start < other.start) {
      result.push(new TimeInterval(this.start, other.start));
    }

    // Part after the other interval
    if (this.end > other.end) {
      result.push(new TimeInterval(other.end, this.end));
    }

    return result;
  }

  /**
   * Static helper to subtract multiple intervals (e.g. blocks) from a set of available intervals.
   */
  static subtractMany(source: TimeInterval[], toSubtract: TimeInterval[]): TimeInterval[] {
    let result = [...source];

    for (const sub of toSubtract) {
      const nextResult: TimeInterval[] = [];
      for (const interval of result) {
        nextResult.push(...interval.subtract(sub));
      }
      result = nextResult;
    }

    return result;
  }

  /**
   * Merges overlapping or adjacent intervals.
   */
  static merge(intervals: TimeInterval[]): TimeInterval[] {
    if (intervals.length <= 1) return intervals;

    const sorted = [...intervals].sort((a, b) => a.start.toMillis() - b.start.toMillis());
    const merged: TimeInterval[] = [];

    let current = sorted[0];

    for (let i = 1; i < sorted.length; i++) {
      const next = sorted[i];
      if (current.end >= next.start) {
        // Overlap or adjacent
        const newEnd = current.end > next.end ? current.end : next.end;
        current = new TimeInterval(current.start, newEnd);
      } else {
        merged.push(current);
        current = next;
      }
    }
    merged.push(current);

    return merged;
  }

  toJSON() {
    return {
      start: this.start.toISO(),
      end: this.end.toISO(),
    };
  }
}
