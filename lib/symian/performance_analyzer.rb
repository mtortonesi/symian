require 'symian/event'
require 'symian/generator'
require 'symian/incident'
require 'symian/operator'
require 'symian/support_group'


module Symian
  class PerformanceAnalyzer
    def initialize(config)
      @warmup_threshold = config.start_time + config.warmup_duration
    end

    def calculate_kpis(trace)
      raise ArgumentError, 'Argument must be a TraceCollector' unless TraceCollector === trace

      kpis = {}

      # these metrics are considered as kpis
      kpis[:all_incidents]        = trace.incidents
      kpis[:incidents_considered] = 0
      kpis[:closed_incidents]     = 0
      kpis[:mean_ttr]             = 0
      kpis[:max_ttr]              = 0
      kpis[:mean_waiting_time]    = 0

      max_ttr = 0
      ttr_sum = 0
      wt_sum  = 0
      trace.with_incidents do |i|

        next if @warmup_threshold and i.arrival_time < @warmup_threshold

        kpis[:incidents_considered] += 1

        if i.closed?
          kpis[:closed_incidents] += 1
          ttr = i.total_work_time
          ttr_sum += ttr
          wt_sum  += i.total_queue_time
          max_ttr = ttr if ttr > max_ttr
        end

      end

      kpis[:max_ttr] = max_ttr
      if kpis[:closed_incidents] == 0
        kpis[:mean_ttr]          = Float::MAX
        kpis[:mean_waiting_time] = Float::MAX
      else
        kpis[:mean_ttr]          = ttr_sum / kpis[:closed_incidents]
        kpis[:mean_waiting_time] = wt_sum / kpis[:closed_incidents]
      end

      # return kpis
      kpis
    end

  end
end
