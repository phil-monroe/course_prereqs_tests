require 'yaml'
require 'pp'
require 'active_support/core_ext'

Course = Struct.new :id, :name, :prereqs do
  def self.all
    @all ||= Dir.glob('courses/*.yml').map{ |f| YAML.load_file(f) }
  end

  def self.index
    @index ||= all.inject(Hash.new){|idx, c| idx[c.id] = c; idx }
  end

  def self.find(id)
    index[id]
  end
end



PreReq = Struct.new :course_id, :alternative_course_ids, :concurrent do
  def course
    Course.find(course_id)
  end

  def alternative_courses
    alternative_course_ids.map{|id| Course.find(id)}
  end

  def is_met? compleated_courses, concurrent_courses
    course_compleated?(compleated_courses) ||
      course_concurrent?(concurrent_courses) ||
      alternatives_compleated?(compleated_courses)
  end

  private

  def course_compleated? compleated_courses
    compleated_courses[course].present?
  end

  def course_concurrent? concurrent_courses
    concurrent_courses.include?(course) && concurrent == true
  end

  def alternatives_compleated? compleated_courses
    alternative_courses.each{ |c|
      return true if compleated_courses[c].present?
    }
    false
  end
end



TermSchedule = Struct.new :course_ids do
  def courses
    course_ids.map{|id| Course.find(id) }
  end

  def prereqs
    courses.map(&:prereqs)
  end

  def index
    courses.inject(Hash.new){|idx, c| idx[c.id] = self; idx }
  end

  def validate compleated_courses
    unmet_prereqs = Hash.new {|h, k| h[k] = []}
    courses.each do |course|
      course.prereqs.each do |prereq|
        unmet_prereqs[course] << prereq unless prereq.is_met?(compleated_courses, courses)
      end
    end
    unmet_prereqs
  end
end



Schedule = Struct.new :terms do
  def add_term term
    self.terms ||= []
    self.terms << term
  end

  alias_method :<<, :add_term

  def validate
    compleated_courses = Hash.new
    self.terms.inject(Hash.new) do |incomplete, term|
      incomplete[term] = term.validate(compleated_courses)
      (term.courses - incomplete[term].keys).each {|c| compleated_courses[c] = term}
      incomplete
    end
  end

  def valid?
    validate.values.each {|v| return false unless v.empty? }
    true
  end
end




schedule = Schedule.new

schedule << TermSchedule.new(['me1010'])
schedule << TermSchedule.new(['me1011', 'me1012'])
schedule << TermSchedule.new(['me1014'])


pp schedule.validate
pp schedule.valid?