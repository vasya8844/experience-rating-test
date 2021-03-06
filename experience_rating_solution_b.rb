# == Schema Information
#
# Table name: experiences
#
# id :integer, not null, primary key
# name :string
# ratings_sum :integer, not null, default: 0
# ratings_count :integer, not null, default: 0

# Table name: feedback
#
# id :integer, not null, primary key
# experience_id :integer

# Table name: responses
#
# id :integer, not null, primary key
# feedback_id :integer
# question :string
# answer :string

# Indexes
#
# index_responses_on_feedback_id (feedback_id)

# Foreign Keys
#
#  fk_rails_...  (responses.feedback_id => feedback.id)

class Experience < ActiveRecord
  has_many :feedback

  def rating
    return 0 unless ratings_count > 0

    ratings_sum.to_f / ratings_count
  end

  # added_removed
  def changed_feedback_response(count_add, score)
    reload

    # possible we can use here built in increment functionality...
    update ratings_count: ratings_count + count_add, ratings_sum: ratings_sum + score
  end

end

class Feedback < ActiveRecord
  belongs_to :experience
  has_many :responses
end

class Response < ActiveRecord
  belongs_to :feedback

  after_create do
    feedback.experience.changed_feedback_response(1, rating_to_score)
  end

  before_destroy do
    feedback.experience.changed_feedback_response(-1, -rating_to_score)
  end

  RATING_QUESTION = 'Rate the experience'

  scope :experience_rates, -> { where(:question => RATING_QUESTION)}

  # to get rid of this step, and add possibility to do db aggregation, need:
  #  - update sourcecode to store only rating in db 1, 2, ...
  #  - migrate existing rating data in responses table
  #  - convert string into number diring `aggregation` db functions

  def rating_to_score
    # TODO: we can use regexp here, but ceep it simple for now
    case answer
    when '5 great', 'awesome (5)'
      5
    when '4 OK', '4'
      4
    when 'not bad 3'
      3­
    when '2 bad'
      2
    when '1 awful'
      1
    else
      raise 'Unknown answer'
    end
  end

end


# Simmilar notes as `solution a`

# Pros: doesn't need to do heavy calculation on user vote process
