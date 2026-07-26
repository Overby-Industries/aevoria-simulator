#include "direct_democracy_os.h"
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

void DirectDemocracyOS::_bind_methods() {
    ClassDB::bind_method(D_METHOD("submit_proposal", "title", "description", "authorUID"), &DirectDemocracyOS::submit_proposal);
    ClassDB::bind_method(D_METHOD("vote_on_proposal", "proposalTitle", "voterUID", "isUpvote"), &DirectDemocracyOS::vote_on_proposal);
    ClassDB::bind_method(D_METHOD("check_and_pass_proposals"), &DirectDemocracyOS::check_and_pass_proposals);
    ClassDB::bind_method(D_METHOD("get_active_proposals"), &DirectDemocracyOS::get_active_proposals);
    ClassDB::bind_method(D_METHOD("get_archived_proposals"), &DirectDemocracyOS::get_archived_proposals);
}

DirectDemocracyOS::DirectDemocracyOS() {}
DirectDemocracyOS::~DirectDemocracyOS() {}

void DirectDemocracyOS::submit_proposal(const String& title, const String& description, const String& authorUID) {
    Proposal newProposal;
    newProposal.title = title;
    newProposal.description = description;
    newProposal.authorUID = authorUID;
    newProposal.upvotes = 0;
    newProposal.downvotes = 0;
    newProposal.isPassed = false;

    activeProposals.push_back(newProposal);
    UtilityFunctions::print("Proposal submitted: ", title);
}

void DirectDemocracyOS::vote_on_proposal(const String& proposalTitle, const String& voterUID, bool isUpvote) {
    for (auto& proposal : activeProposals) {
        if (proposal.title == proposalTitle) {
            if (isUpvote) {
                proposal.upvotes++;
            } else {
                proposal.downvotes++;
            }
            UtilityFunctions::print("Vote cast on proposal: ", proposalTitle);
            return;
        }
    }
    UtilityFunctions::print("Proposal not found: ", proposalTitle);
}

void DirectDemocracyOS::check_and_pass_proposals() {
    // godot::Vector has no iterator-based erase() (only erase-by-value and
    // remove_at(index)), so this walks by index instead of iterator.
    for (int i = 0; i < activeProposals.size(); ) {
        Proposal &proposal = activeProposals.write[i];

        if (proposal.upvotes > proposal.downvotes && proposal.upvotes >= 100) {
            String passed_title = proposal.title;

            proposal.isPassed = true;
            archivedProposals.push_back(proposal);

            activeProposals.remove_at(i); // shifts later elements down; don't advance i

            UtilityFunctions::print("Proposal passed: ", passed_title);
        }
        else {
            ++i;
        }
    }
}

Array DirectDemocracyOS::get_active_proposals() {
    Array proposals;
    for (const auto& proposal : activeProposals) {
        Dictionary proposalDict;
        proposalDict["title"] = proposal.title;
        proposalDict["description"] = proposal.description;
        proposalDict["authorUID"] = proposal.authorUID;
        proposalDict["upvotes"] = proposal.upvotes;
        proposalDict["downvotes"] = proposal.downvotes;
        proposals.push_back(proposalDict);
    }
    return proposals;
}

Array DirectDemocracyOS::get_archived_proposals() {
    Array proposals;
    for (const auto& proposal : archivedProposals) {
        Dictionary proposalDict;
        proposalDict["title"] = proposal.title;
        proposalDict["description"] = proposal.description;
        proposalDict["authorUID"] = proposal.authorUID;
        proposalDict["upvotes"] = proposal.upvotes;
        proposalDict["downvotes"] = proposal.downvotes;
        proposals.push_back(proposalDict);
    }
    return proposals;
}
