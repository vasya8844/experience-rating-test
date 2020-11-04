# == Schema Information
#
# Table name: experiences
#
# id :integer, not null, primary key
# name :string
# rating :float, null

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

  # calculate rating on-demand
  def rating
    return read_attribute(:rating) if read_attribute(:rating)

    update rating: calculate_rating

    read_attribute(:rating)
  end

  private

  def calculate_rating
    responses = feedback.responses
    return 0 unless responses.count > 0

    total_sum = feedback.responses.experience_rates.sum { |response| response.rating_to_score }

    (total_sum.to_f / responses.count).round(2)
  end

end

class Feedback < ActiveRecord
  belongs_to :experience
  has_many :responses
end

class Response < ActiveRecord
  belongs_to :feedback

  after_save :reset_experience_rating
  before_destroy :reset_experience_rating

  RATING_QUESTION = 'Rate the experience'

  scope :experience_rates, -> { where(:question => RATING_QUESTION)}

  private

  def reset_experience_rating
    # just reset experience rating and don't do any calculations
    feedback.experience.update rating: nil if question == RATING_QUESTION
  end

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
