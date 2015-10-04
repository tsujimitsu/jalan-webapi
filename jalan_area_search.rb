require "net/http"
require "uri"
require "rexml/document"

#JALAN_API_KEY=XXXXXX
#export JALAN_API_KEY

def parameterize(params)
  params.map{|k,v| "#{k}=#{v}"}.join('&')
end


def stock_parse(doc)
  plan = Hash.new { |h,k| h[k] = {} }
  
  doc.elements.each('Results/Plan') do |e|
    plancd = e.elements['PlanCD'].text
    plan[plancd] = {}
    plan[plancd]['sum'] = 0
    plan[plancd]['PlanName'] = e.elements['PlanName'].text
    plan[plancd]['PlanDetailURL'] = e.elements['PlanDetailURL'].text

    e.elements.each('Stay/Date') do |i|
      begin
        day = i.attributes["year"] + i.attributes["month"] + i.attributes["date"]
        plan[plancd][day] = {}
        
        if i.elements['Stock'].text.nil?
          plan[plancd][day]['Stock'] = "有"
        else
          plan[plancd][day]['Stock'] = i.elements['Stock'].text
        end
        
        plan[plancd][day]['Rate'] = i.elements['Rate'].text
        plan[plancd]['sum'] += i.elements['Rate'].text.to_i
      rescue => ex
        puts "Exception: " + ex.message
      end
    end
  end
  
  return plan
end

def stock_parse_print(doc)

  # result number of search
  # puts doc.elements['Results/NumberOfResults'].text

  # result all of search
  doc.elements.each('Results/Plan') do |e|
    puts e.elements['PlanName'].text
    puts e.elements['PlanDetailURL'].text

    e.elements.each('Stay/Date') do |i|
      begin
        print i.attributes["year"] + "/" + i.attributes["month"] + "/" + i.attributes["date"]

        if i.elements['Stock'].text.nil?
          print " - 残数：有"
        else
          print " - 残数：" + i.elements['Stock'].text
        end

        print " - 価格：" + i.elements['Rate'].text
        puts ""

      rescue => ex
        puts "Exception: " + ex.message
      end
    end
  end
end 


def stock_search(a, b, c, d, e, f, g, h, i)
  params = {
    key: ENV['JALAN_API_KEY'],
    l_area: a,
    stay_date: b,
    stay_count: c,
    room_count: d,
    adult_num: e,
    min_rate: f,
    max_rate: g,
    order: h,
    count: i 
  }
  uri = URI("http://jws.jalan.net/APIAdvance/StockSearch/V1/?" + parameterize(params)) 
  response = Net::HTTP.get_response(uri)
  return response
end


result = {}
["136200","136500","136800","137100","137400","137700","138000","138300","138600","138900","139200","139500","139800"].each do |l_area|
  response = stock_search(l_area,"20151010","2","1","2","10000","16000","2","100")
  if response.code == "200"
    doc = REXML::Document.new(response.body)
    result = result.merge(stock_parse(doc))

  else
    #puts l_area
    puts response.code

  end

  sleep(120)
end

#response = stock_search("136200","20151010","2","1","2","10000","16000","2","100")

#puts result["00061701"]
puts result.sort_by{|key,val| val['sum']}
