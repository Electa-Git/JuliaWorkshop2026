# import UnicodePlots
import TimeToPublication

mypaper = TimeToPublication.Paper(60, 90)
days_to_publication = TimeToPublication.simulate(mypaper, 10_000)

TimeToPublication.display_result(days_to_publication)
