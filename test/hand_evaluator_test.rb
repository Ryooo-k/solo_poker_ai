# frozen_string_literal: true

require "minitest/autorun"
require "minitest/spec"
require_relative "../lib/hand_evaluator"

describe HandEvaluator do
  it "ワンペア完成までの距離を計算できる" do
    assert_equal 0, distance(:one_pair, [101, 201, 303, 404, 105])
    assert_equal 1, distance(:one_pair, [101, 202, 303, 404, 105])
  end

  it "フルハウス、ツーペアの場合、ワンペア完成の判定結果となる" do
    assert_equal 0, distance(:one_pair, [101, 201, 309, 409, 109])
    assert_equal 0, distance(:one_pair, [101, 201, 104, 204, 413])
  end

  it "スリーカード、フォーカードの場合、ワンペアは未完成となる" do
    assert_equal 1, distance(:one_pair, [101, 201, 301, 405, 109])
    assert_equal 1, distance(:one_pair, [101, 201, 301, 401, 413])
  end

  it "ツーペア完成までの距離を計算できる" do
    assert_equal 0, distance(:two_pair, [101, 201, 303, 403, 105])
    assert_equal 1, distance(:two_pair, [101, 201, 303, 404, 105])
    assert_equal 2, distance(:two_pair, [101, 202, 303, 404, 105])
  end

  it "スリーカードからツーペア完成までの最少交換枚数を計算できる" do
    assert_equal 1, distance(:two_pair, [101, 201, 301, 402, 105])
  end

  it "フルハウスの場合、ツーペアは未完成となる" do
    assert_equal 1, distance(:two_pair, [101, 201, 303, 403, 103])
    assert_equal 1, distance(:two_pair, [101, 201, 301, 103, 203, 303])
    assert_equal 1, distance(:two_pair, [101, 201, 301, 401, 103, 203])
  end

  it "フォーカードの場合、ツーペアは未完成となる" do
    assert_equal 2, distance(:two_pair, [101, 201, 301, 401, 103])
  end

  it "スリーカード完成までの距離を計算できる" do
    assert_equal 0, distance(:thiree, [101, 201, 301, 404, 105])
    assert_equal 1, distance(:thiree, [101, 201, 303, 404, 105])
    assert_equal 2, distance(:thiree, [101, 202, 303, 404, 105])
  end

  it "フルハウスの場合、スリーカードは完成となる" do
    assert_equal 0, distance(:thiree, [101, 201, 303, 403, 103])
    assert_equal 0, distance(:thiree, [101, 201, 303, 403, 103, 413])
  end

  it "フォーカードの場合、スリーカードは未完成となる" do
    assert_equal 1, distance(:thiree, [101, 201, 301, 401, 103])
  end

  it "スートに関係なくストレート完成までの距離を計算できる" do
    assert_equal 0, distance(:straight, [101, 202, 303, 404, 105])
    assert_equal 1, distance(:straight, [102, 203, 304, 405, 113])
    assert_equal 3, distance(:straight, [101, 201, 105, 209, 313])
    assert_equal 4, distance(:straight, [102, 202, 302, 402, 109])
  end

  it "ストレートではエースを最小または最大のランクとして扱う" do
    assert_equal 0, distance(:straight, [101, 202, 303, 404, 105])
    assert_equal 0, distance(:straight, [110, 211, 312, 413, 101])
  end

  it "エースを含まないストレートを判定できる" do
    assert_equal 0, distance(:straight, [102, 203, 304, 405, 106])
    assert_equal 0, distance(:straight, [109, 210, 311, 412, 113])
  end

  it "エースをまたいで循環する並びはストレートにならない" do
    assert_equal 2, distance(:straight, [112, 213, 301, 402, 103])
  end

  it "重複したランクはストレートの距離を余分に減らさない" do
    assert_equal 2, distance(:straight, [101, 201, 102, 203, 109])
  end

  it "フラッシュ完成までの距離を計算できる" do
    assert_equal 0, distance(:flush, [101, 103, 105, 107, 109])
    assert_equal 0, distance(:flush, [101, 103, 105, 107, 109, 413])
    assert_equal 0, distance(:flush, [101, 103, 105, 107, 109, 111])
    assert_equal 1, distance(:flush, [101, 103, 105, 107, 209])
    assert_equal 2, distance(:flush, [101, 103, 105, 207, 309])
    assert_equal 3, distance(:flush, [101, 202, 303, 404, 405])
  end

  it "フルハウス完成までの距離を計算できる" do
    assert_equal 0, distance(:full_house, [101, 201, 301, 403, 103])
    assert_equal 0, distance(:full_house, [101, 201, 301, 403, 303, 203])
    assert_equal 0, distance(:full_house, [101, 201, 103, 403, 303, 203])
    assert_equal 1, distance(:full_house, [101, 201, 102, 202, 303, 403])
    assert_equal 1, distance(:full_house, [101, 201, 301, 403, 105])
    assert_equal 1, distance(:full_house, [101, 201, 303, 403, 105])
    assert_equal 2, distance(:full_house, [101, 201, 303, 404, 105])
    assert_equal 3, distance(:full_house, [101, 202, 303, 404, 105])
  end

  it "フォーカードからフルハウス完成までの最少交換枚数を計算できる" do
    assert_equal 1, distance(:full_house, [101, 201, 301, 401, 105])
  end

  it "フォーカード完成までの距離を計算できる" do
    assert_equal 0, distance(:four, [101, 201, 301, 401, 105])
    assert_equal 1, distance(:four, [101, 201, 301, 404, 105])
    assert_equal 2, distance(:four, [101, 201, 303, 404, 105])
    assert_equal 3, distance(:four, [101, 202, 303, 404, 105])
  end

  it "ランクとスートの両方からストレートフラッシュの距離を計算する" do
    assert_equal 0, distance(:straight_flush, [101, 102, 103, 104, 105])
    assert_equal 1, distance(:straight_flush, [201, 202, 203, 204, 305])
    assert_equal 2, distance(:straight_flush, [102, 103, 104, 208, 313])
    assert_equal 3, distance(:straight_flush, [102, 103, 208, 309, 413])
    assert_equal 4, distance(:straight_flush, [102, 109, 203, 304, 405])
  end

  it "エースを含まないストレートフラッシュを判定できる" do
    assert_equal 0, distance(:straight_flush, [302, 303, 304, 305, 306])
  end

  it "ストレートフラッシュの場合、ストレート・フラッシュも完成する" do
    hands = [101, 102, 103, 104, 105]
    assert_equal 0, distance(:straight_flush, hands)
    assert_equal 0, distance(:flush, hands)
    assert_equal 0, distance(:straight, hands)
  end

  it "ロイヤルストレートフラッシュ完成までの距離を計算できる" do
    assert_equal 0, distance(:royal_straight_flush, [101, 110, 111, 112, 113])
    assert_equal 1, distance(:royal_straight_flush, [201, 210, 211, 212, 305])
    assert_equal 2, distance(:royal_straight_flush, [101, 110, 111, 202, 303])
    assert_equal 4, distance(:royal_straight_flush, [101, 202, 303, 404, 105])
    assert_equal 5, distance(:royal_straight_flush, [102, 203, 304, 405, 106])
  end

  it "ロイヤルのランクが揃っていてもスートが異なる場合は未完成となる" do
    hands = [101, 210, 311, 412, 113]

    assert_equal 0, distance(:straight, hands)
    assert_equal 3, distance(:royal_straight_flush, hands)
  end

  it "ロイヤルストレートフラッシュの場合、ストレートフラッシュ・ストレート・フラッシュも完成する" do
    hands = [401, 410, 411, 412, 413]
    assert_equal 0, distance(:royal_straight_flush, hands)
    assert_equal 0, distance(:straight_flush, hands)
    assert_equal 0, distance(:flush, hands)
    assert_equal 0, distance(:straight, hands)
  end

  it "手札が6枚でも余分な1枚に影響されずストレート系の距離を計算する" do
    hands = [201, 210, 211, 212, 413, 213]

    assert_equal 0, distance(:straight, hands)
    assert_equal 0, distance(:flush, hands)
    assert_equal 0, distance(:straight_flush, hands)
    assert_equal 0, distance(:royal_straight_flush, hands)
  end

  it "手札が6枚の場合も手札全体のランク構成から各役までの距離を計算する" do
    hands = [101, 201, 301, 403, 103, 105]

    assert_equal 0, distance(:one_pair, hands)
    assert_equal 1, distance(:two_pair, hands)
    assert_equal 0, distance(:thiree, hands)
    assert_equal 0, distance(:full_house, hands)
  end

  it "カードの並び順によって判定結果が変わらない" do
    hands = [101, 201, 301, 403, 103, 105]

    assert_equal HandEvaluator.call(hands), HandEvaluator.call(hands.reverse)
  end

  private

  def distance(rank, hands)
    HandEvaluator.call(hands).fetch(rank)
  end
end
