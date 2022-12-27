## Support whole-calendar-day calculations.
## Use treeform/chrono for anything more complex.

import std / times

type
  # not trying to look like std/times DateTime
  # monthdayZero and monthZero there seem to mean that 0 represents uninitialised
  # these are natural, one-based months and days
  Date* {.exportc: "CDate".} = object # tuple doesn't preserve exported field names
    y*: int
    m*: Month
    d*: MonthDayRange
  EpochDay* = int64

proc toDate*(y, m, d: int): Date {.exportc, cdecl.} = # TODO try just using compound literal on c struct
  echo "got here with ", y, m, d
  result = Date(y: y, m: m.Month, d: d)
  echo "and here with ",result

converter toDate*(dt: DateTime): Date =
  Date(y: dt.year, m: dt.month, d: dt.monthday)

proc dayOfWeekIso*(d: Date): int {.exportc, cdecl.} =
  ## ISO-8601 Monday = 1 to Sunday = 7
  getDayOfWeek(d.d, d.m, d.y).ord + 1

# Lightly adjusted copypaste unexported procs from std/times
# ---8<--
proc toEpochDay*(d: Date): EpochDay =
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
  era * 146097 + doe - 719468
  
proc toDate*(epochday: EpochDay): Date =
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
  Date(y: (y + ord(m <= 2)).int, m: m.Month, d: d.MonthdayRange)
# -->8---

proc `~`*(d1, d2: Date): int =
  ## Date difference in whole calendar days.
  ## Different to `-`*(dt1, dt2: DateTime): Duration
  (d1.toEpochDay - d2.toEpochDay).int
  
proc weeksUntil*(d1, d2: Date): int =
  ## Whole weeks.
  (d2 ~ d1) div 7

# TODO template?
proc `<`*(d1, d2: Date): bool =
  d1.toEpochDay < d2.toEpochDay
proc `<=`*(d1, d2: Date): bool =
  d1.toEpochDay <= d2.toEpochDay
proc `>`*(d1, d2: Date): bool =
  d1.toEpochDay > d2.toEpochDay
proc `>=`*(d1, d2: Date): bool =
  d1.toEpochDay >= d2.toEpochDay
proc `+`*(d: Date, o: int): Date =
  (d.toEpochDay + o).toDate
proc `-`*(d: Date, o: int): Date =
  (d.toEpochDay - o).toDate
  
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
  
# Self-test
when isMainModule:
  doAssert dateTime(2020, mJan, 2) ~ dateTime(2020, mJan, 1) == 1
