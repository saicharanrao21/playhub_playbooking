import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { DateTime } from 'luxon';
import { DayOfWeek, PricingRule } from '@prisma/client';

export interface PricingResult {
  totalPrice: number;
  currency: string;
  breakdown: Array<{
    startTime: string;
    endTime: string;
    price: number;
    ruleName: string;
  }>;
}

@Injectable()
export class PricingService {
  private readonly logger = new Logger(PricingService.name);

  constructor(private prisma: PrismaService) {}

  async calculatePrice(
    facilityId: string,
    startTime: Date,
    endTime: Date,
    timezone: string = 'UTC',
  ): Promise<PricingResult> {
    const startDt = DateTime.fromJSDate(startTime).setZone(timezone);
    const endDt = DateTime.fromJSDate(endTime).setZone(timezone);

    const rules = await this.prisma.pricingRule.findMany({
      where: {
        facilityId,
        isActive: true,
        OR: [
          { effectiveFrom: null },
          { effectiveFrom: { lte: endTime } },
        ],
        AND: [
          {
            OR: [
              { effectiveTo: null },
              { effectiveTo: { gte: startTime } },
            ],
          },
        ],
      },
      orderBy: { priority: 'desc' },
    });

    if (rules.length === 0) {
      throw new Error('No active pricing rules found for this facility');
    }

    // We split the interval into 30-minute chunks for granular pricing calculation.
    // Or we can find all transition points (startTimes/endTimes of rules).
    const transitions = new Set<number>();
    transitions.add(startDt.toMillis());
    transitions.add(endDt.toMillis());

    // Transition points from rules (within the day)
    // This is slightly complex because rules can repeat daily.
    // For simplicity in this foundation, we'll use 15-minute granularity or check transitions.
    // Transition points: startDt, endDt, and any rule boundaries that fall between them.

    // Actually, let's just use 15-minute increments to calculate.
    let total = 0;
    const breakdown = [];
    const currency = rules[0].currency;

    let current = startDt;
    const stepMinutes = 15;

    while (current < endDt) {
      const next = current.plus({ minutes: stepMinutes });
      const segmentEnd = next > endDt ? endDt : next;
      const durationHours = segmentEnd.diff(current, 'hours').hours;

      const matchedRule = this.findBestRule(rules, current);
      if (!matchedRule) {
         throw new Error(`No pricing rule matched for interval ${current.toISO()} - ${segmentEnd.toISO()}`);
      }

      const segmentPrice = Number(matchedRule.basePrice) * durationHours;
      total += segmentPrice;

      // Group breakdown by rule to avoid too many entries
      if (breakdown.length > 0 && breakdown[breakdown.length - 1].ruleName === matchedRule.name) {
        breakdown[breakdown.length - 1].endTime = segmentEnd.toISO();
        breakdown[breakdown.length - 1].price += segmentPrice;
      } else {
        breakdown.push({
          startTime: current.toISO(),
          endTime: segmentEnd.toISO(),
          price: segmentPrice,
          ruleName: matchedRule.name,
        });
      }

      current = next;
    }

    return {
      totalPrice: total,
      currency,
      breakdown,
    };
  }

  private findBestRule(rules: PricingRule[], time: DateTime): PricingRule | null {
    const dow = time.weekdayLong.toUpperCase() as DayOfWeek;
    const timeStr = time.toFormat('HH:mm');

    for (const rule of rules) {
      // 1. Check Day of Week
      if (rule.daysOfWeek.length > 0 && !rule.daysOfWeek.includes(dow)) {
        continue;
      }

      // 2. Check Time Window (if defined)
      if (rule.startTime && rule.endTime) {
        // Handle normal window
        if (rule.startTime <= rule.endTime) {
           if (timeStr < rule.startTime || timeStr >= rule.endTime) continue;
        } else {
           // Handle overnight window (e.g. 22:00 - 02:00)
           if (timeStr < rule.startTime && timeStr >= rule.endTime) continue;
        }
      }

      // 3. Check Effective Dates
      if (rule.effectiveFrom && time.toJSDate() < rule.effectiveFrom) continue;
      if (rule.effectiveTo && time.toJSDate() > rule.effectiveTo) continue;

      return rule;
    }

    return null;
  }
}
