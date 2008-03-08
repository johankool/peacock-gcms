#! /usr/bin/env python

from citeproc import CiteProcessor

class TestReferenceList:

    def test_setup():
        data = [
          {
            "type": "Article",
            "title": "Some Title", 
            "year": "1999", 
            "author": [{"given_name":"Jane", "family_name":"Doe"}]
          },
          {
            "type": "NewsArticle",
            "title": "News Title", 
            "year": "2002", 
            "periodical": {"title":"Newsweek"}
          },
          {
            "type": "Article",
            "title": "XYZ", 
            "year": "1999", 
            "author": [
                        {"given_name":"Jane", "family_name":"Doe"},
                        {"given_name":"Susan", "family_name":"Smith"}
                      ]
          },
          {
            "type": "NewsArticle",
            "title": "Second News Title", 
            "year": "2002", 
            "periodical": {"title":"Newsweek"}
          },
          {
            "type": "Article",
            "title": "Another Title", 
            "year": "1999", 
            "author": [{"given_name":"Jane", "family_name":"Doe"}]
          }
        ]
        list = ReferenceList(style="apa")
        # not sure how to load the authors; maybe there needs to be an AgentList 
        # list object that these get loaded into, and the author, etc. array is 
        # then just pointers to that. But does Reference need a method to handle 
        # this?  -- bruce
        for item in data:
            reference = Reference.new(title=item["title"], year=item["year"], type=item["type"])
            list.add(reference)
        print list
        print "Finished test_setup"

    # first test basic author-year grouping and sorting
    def test_reference_grouping_sorting():
        # use itertools groupby?
        assert list[1].suffix == "b"
        assert list[2].suffix == nil
        print "Finished test_reference_grouping_sorting"

    # test that substitution works properly where there is no author
    def test_reference_grouping_sorting_substitution():
        assert list[3].suffix == "a"
        print "Finished test_reference_grouping_sorting_substitution"
    
if __name__ == "__main__":
    print "Start TestReferenceList"
    test = TestReferenceList()
    test.test_setup
    test.test_reference_grouping_sorting
    test.test_reference_grouping_sorting_substitution
    print "Finished TestReferenceList"

