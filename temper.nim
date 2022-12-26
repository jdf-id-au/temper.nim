## Support whole-calendar-day calculations
## Different to `-`(dt1, dt2: DateTime): Duration

import std / times

type
  # not trying to look exactly like std/times DateTime
  # monthdayZero and monthZero there seem to mean that 0 represents uninitialised
  Date* = tuple[d: MonthdayRange, m: Month, y: int]
  EpochDay* = int64

proc date*(y, m, d: int): Date =
  (d.MonthdayRange, m.Month, y).Date

converter toDate*(dt: DateTime): Date =
  (dt.monthday, dt.month, dt.year).Date

proc dayOfWeekISO*(d: Date): int =
  ## ISO-8601 Monday = 1 to Sunday = 7
  getDayOfWeek(d.d, d.m, d.y).ord + 1

# Minimally changed copypaste unexported procs from std/times ---8<--
func epochDay*(d: Date): EpochDay =
  ## Get the epoch day from a year/month/day date.
  ## The epoch day is the number of days since 1970/01/01
  ## (it might be negative).
  # Based on http://howardhinnant.github.io/date_algorithms.html
  #assertValidDate monthday, month, year
  var
    y = d.y
    m = d.m.ord
    d = d.d.int
  if m <= 2:
    y.dec
  let era = (if y >= 0: y else: y-399) div 400
  let yoe = y - era * 400
  let doy = (153 * (m + (if m > 2: -3 else: 9)) + 2) div 5 + d-1
  let doe = yoe * 365 + yoe div 4 - yoe div 100 + doy
  return era * 146097 + doe - 719468
  
func date*(epochday: EpochDay): Date =
  ## Get the year/month/day date from a epoch day.
  ## The epoch day is the number of days since 1970/01/01
  ## (it might be negative).
  # Based on http://howardhinnant.github.io/date_algorithms.html
  var z = epochday
  z.inc 719468
  let era = (if z >= 0: z else: z - 146096) div 146097
  let doe = z - era * 146097
  let yoe = (doe - doe div 1460 + doe div 36524 - doe div 146096) div 365
  let y = yoe + era * 400;
  let doy = doe - (365 * yoe + yoe div 4 - yoe div 100)
  let mp = (5 * doy + 2) div 153
  let d = doy - (153 * mp + 2) div 5 + 1
  let m = mp + (if mp < 10: 3 else: -9)
  return (d.MonthdayRange, m.Month, (y + ord(m <= 2)).int)
# -->8---

func `~`*(d1, d2: Date): int =
  ## Date difference in whole calendar days.
  (d1.epochDay - d2.epochDay).int
  
proc weeksUntil*(d1, d2: Date): int =
  ## Whole weeks.
  (d2 ~ d1) div 7

# TODO template?
proc `<`*(d1, d2: Date): bool =
  d1.epochDay < d2.epochDay
proc `<=`*(d1, d2: Date): bool =
  d1.epochDay <= d2.epochDay
proc `>`*(d1, d2: Date): bool =
  d1.epochDay > d2.epochDay
proc `>=`*(d1, d2: Date): bool =
  d1.epochDay >= d2.epochDay
proc `+`*(d: Date, o: int): Date =
  (d.epochDay + o).date
proc `-`*(d: Date, o: int): Date =
  (d.epochDay - o).date
  
proc format*(d: Date, f="yyyy-MM-dd"): string =
  let dt = dateTime(d.y, d.m, d.d)
  format(dt, f)

proc `$`*(d: Date): string =
  d.format
  
converter toFloat*(d: Duration): float =
  ## One second resolution.
  d.inSeconds.float

converter toFloat*(dt: DateTime): float =
  ## One second resolution.
  dt.toTime.toUnix.float

when isMainModule:
  doAssert dateTime(2020, mJan, 2) ~ dateTime(2020, mJan, 1) == 1
