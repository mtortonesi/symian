module Symian
  class WorkShift

    def initialize(type, params={})
      case type
        when :predefined
          # get workshift id
          raise ArgumentError unless params[:id]
          wsid = params[:id]

          # retrieve predefined workshift
          predefined_workshift = WORKSHIFT_TABLE[wsid]
          raise ArgumentError unless predefined_workshift

          # load start_time and end_time from predefined workshift
          @start_time = predefined_workshift[:start_time]
          @end_time   = predefined_workshift[:end_time]
        when :custom
          # load start_time and end_time from parameters
          raise ArgumentError unless params[:start_time] and params[:end_time]
          @start_time = params[:start_time]
          @end_time   = params[:end_time]
        when :all_day_long
          # nothing to do
        else
          raise ArgumentError
      end

      # save work shift type
      @type = type

      unless @type == :all_day_long
        # normalize start_time and end_time by transforming them from
        # instances of (Date)Time class to integers representing the
        # number of seconds elapsed from last midnight UTC
        @start_time = @start_time.utc.seconds_since_midnight.round
        @end_time   = @end_time.utc.seconds_since_midnight.round

        # check if it is an overnight work shift
        @overnight = (@type == :all_day_long ? false : @end_time < @start_time)
      end
    end


    def active_at?(time)
      return true if @type == :all_day_long

      t = time.utc.seconds_since_midnight.round
      if @overnight
        t < @end_time or t >= @start_time
      else
        @start_time <= t and t < @end_time
      end
    end


    def secs_to_end_of_shift(time)
      return Infinity if @type == :all_day_long

      t = time.utc.seconds_since_midnight.round
      res = if @overnight
        if t < @end_time
          @end_time - t
        else # if t > @start_time
          @end_time + 1.day.to_i - t
        # TODO: else raise error
        end
      else
        # TODO: raise error if t < @start_time or t > @end_time
        @end_time - t
      end

      # need to convert to integer
      res.round
    end


    def secs_to_begin_of_shift(time)
      raise RuntimeError if active_at?(time)

      t = time.utc.seconds_since_midnight.round
      res = if @overnight
        # TODO: raise error if t < @end_time or t > @start_time
        @start_time - t
      else
        if t < @start_time
          @start_time - t
        else # if t > @end_time
          @start_time + 1.day - t
        # TODO: else raise error
        end
      end

      # need to convert to integer
      res.round
    end


    def duration
      return Infinity if @type == :all_day_long

      res = if @overnight
        1.day.to_i - @start_time + @end_time
      else
        @end_time - @start_time
      end

      # need to convert to integer
      res.round
    end


    # 24x7 work shift
    WORKSHIFT_24x7 = WorkShift.new(:all_day_long)

    # an infinitely large value
    Infinity = 1.0/0.0

    # the predefined work shift table
    WORKSHIFT_TABLE = {
      brt: { # UTC-3, 9AM to 5PM
        start_time: Time.utc(2000, 'Jan', 1, 12, 0, 0),
        end_time:   Time.utc(2000, 'Jan', 1, 20, 0, 0),
      },
      brst: { # UTC-2, 9AM to 5PM
        start_time: Time.utc(2000, 'Jan', 1, 11, 0, 0),
        end_time:   Time.utc(2000, 'Jan', 1, 19, 0, 0),
      },
      est: { # UTC-5, 9AM to 5PM
        start_time: Time.utc(2000, 'Jan', 1, 14, 0, 0),
        end_time:   Time.utc(2000, 'Jan', 1, 22, 0, 0),
      },
      edt: { # UTC-4, 9AM to 5PM
        start_time: Time.utc(2000, 'Jan', 1, 13, 0, 0),
        end_time:   Time.utc(2000, 'Jan', 1, 21, 0, 0),
      },
      cet: { # UTC+1, 9AM to 5PM
        start_time: Time.utc(2000, 'Jan', 1,  8, 0, 0),
        end_time:   Time.utc(2000, 'Jan', 1, 16, 0, 0),
      },
      cest: { # UTC+2, 9AM to 5PM
        start_time: Time.utc(2000, 'Jan', 1,  7, 0, 0),
        end_time:   Time.utc(2000, 'Jan', 1, 15, 0, 0),
      },
      ist: { # UTC+5:30, 9AM to 5PM
        start_time: Time.utc(2000, 'Jan', 1,  3, 30, 0),
        end_time:   Time.utc(2000, 'Jan', 1, 11, 30, 0),
      },
    }
  end
end
