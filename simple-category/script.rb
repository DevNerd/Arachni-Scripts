CATEGORY_URL = 'https://host/categories'

# find the categories form
categories_form = forms_from_response( f.http.get( CATEGORY_URL, async: false ).response ).
    select { |f| f.has_inputs? :expected_input_name_of_the_form }.first

# this will find the ad form, we put it in a proc because it needs to be called
# before #audit submits each mutation
get_ad_form = proc do |mutation|
    # fill in the form with the categories you want and refresh it to grab a valid CSRF token
    # before submitting it
    ad_res = categories_form.update( category: 1, sub_category: 2 ).
        refresh.submit( async: false ).response

    # get the ad form
    ad_form = forms_from_response( ad_res ).first

    # if we have a mutation it means that we were called by #audit so
    # let's update the fresh form we just grabbed with the changes the mutation
    # inputs sustained and then set the merged inputs as the mutation's inputs
    #
    # then return nil to signal #audit to ignore the return value and just
    # submit the updated mutation
    if mutation
        mutation.auditable = ad_form.update( mutation.changes ).auditable
        next
    end

    ad_form
end

# find the ad form
ad_form = get_ad_form.call

# and now audit it and inform the #audit method to call the refresher block
# for each mutation
ad_form.audit 'test', auditor: auditor, each_mutation: get_ad_form do |res|
    # inspect stuff...
    ap res.effective_url
    ap res.request.params
end

# run the queued audit requests
f.http.run