#ifndef DIRECT_DEMOCRACY_OS_H
#define DIRECT_DEMOCRACY_OS_H

#include <gdextension_interface.h>
#include <godot.hpp>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/array.hpp>
#include <vector>
#include <string>

using namespace godot;

class DirectDemocracyOS : public Node {
    GDCLASS(DirectDemocracyOS, Node)

private:
    struct Proposal {
        String title;
        String description;
        String authorUID;
        int upvotes;
        int downvotes;
        bool isPassed;
    };

    std::vector<Proposal> activeProposals;
    std::vector<Proposal> archivedProposals;

public:
    DirectDemocracyOS();
    ~DirectDemocracyOS();

    void _bind_methods();

    void submit_proposal(const String& title, const String& description, const String& authorUID);
    void vote_on_proposal(const String& proposalTitle, const String& voterUID, bool isUpvote);
    void check_and_pass_proposals();
    Array get_active_proposals();
    Array get_archived_proposals();
};

#endif // DIRECT_DEMOCRACY_OS_H