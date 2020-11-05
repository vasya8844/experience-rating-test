# == Schema Information
#
# Table name: experiences
#
# id :integer, not null, primary key
# name :string

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
    score_sum = 0
    ratings_count = 0
    feedback.responses.experience_rates.select('answer, count(*) cnt').group(:answer).each do |response|
      score_sum += response.rating_to_score
      ratings_count += response[:cnt]
    end

    return 0 if ratings_count == 0

    (score_sum.to_f / ratings_count).round(2)
  end

end

class Feedback < ActiveRecord
  belongs_to :experience
  has_many :responses
end

class Response < ActiveRecord
  belongs_to :feedback

  scope :experience_rates, -> { where(:question => 'Rate the experience')}

  private

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


# Need:
#  - add index `experience_id` to `feedback` table
#  - add index `question` to `responses` table

# Cons: we should go through each response in ruby code.
#  - would be better to calculate sum and averate in DB directly.
#  - responses.question field is string, possible better to create separated table `questions`

# Pros: it looks simle
