use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};

#[derive(Serialize)]
pub(crate) struct Clay {
    pub(crate) id: i32,
    pub(crate) name: String,
    pub(crate) description: Option<String>,
    pub(crate) shrinkage: f64,
}

#[derive(Deserialize, Serialize, PartialEq, Debug, Clone)]
pub(crate) enum State {
    Thrown,
    Trimming,
    AwaitingBisqueFiring,
    AwaitingGlazeFiring,
    Finished,
    Recycled,
    Unknown,
}

impl From<i32> for State {
    fn from(id: i32) -> Self {
        match id {
            1 => State::Thrown,
            2 => State::Trimming,
            3 => State::AwaitingBisqueFiring,
            4 => State::AwaitingGlazeFiring,
            5 => State::Finished,
            6 => State::Recycled,
            _ => State::Unknown,
        }
    }
}

impl From<State> for i32 {
    fn from(state: State) -> Self {
        match state {
            State::Thrown => 1,
            State::Trimming => 2,
            State::AwaitingBisqueFiring => 3,
            State::AwaitingGlazeFiring => 4,
            State::Finished => 5,
            State::Recycled => 6,
            State::Unknown => 0
        }
    }
}

pub(crate) fn is_valid_transition(previous_state: State, current_state: State) -> bool {
    match (previous_state, current_state) {
        (State::Thrown, State::Trimming) => true,
        (State::Trimming, State::AwaitingBisqueFiring) => true,
        (State::AwaitingBisqueFiring, State::AwaitingGlazeFiring) => true,
        (State::AwaitingGlazeFiring, State::Finished) => true,
        (State::Recycled, State::Thrown) => true,
        (previous, State::Recycled) => {
            previous != State::Finished && previous != State::Unknown
        }
        _ => false,
    }
}

#[derive(Serialize)]
pub(crate) struct Project {
    pub(crate) id: i32,
    pub(crate) name: String,
    pub(crate) description: Option<String>,
    pub(crate) images: Images,
    pub(crate) created_at: NaiveDateTime,
}

#[derive(Deserialize, Debug)]
pub(crate) struct PutProject {
    pub(crate) name: String,
    pub(crate) description: Option<String>,
    pub(crate) thumbnail: Option<String>,
}

#[derive(Serialize)]
pub(crate) struct ApiResourceReference {
    pub(crate) id: i32,
    pub(crate) url: String,
}

pub(crate) enum ApiResource {
    Project,
    Work,
}

impl From<(ApiResource, i32)> for ApiResourceReference {
    fn from(item: (ApiResource, i32)) -> Self {
        let (resource, id) = item;
        let url = match resource {
            ApiResource::Project => format!("/projects/{}", id),
            ApiResource::Work => format!("/works/{}", id),
        };

        ApiResourceReference { id, url }
    }
}

#[derive(Serialize)]
pub(crate) struct CurrentState {
    pub(crate) state: State,
    pub(crate) transitioned_at: NaiveDateTime,
}

#[derive(Serialize)]
pub(crate) struct Work {
    pub(crate) id: i32,
    pub(crate) project: ApiResourceReference,
    pub(crate) name: String,
    pub(crate) notes: Option<String>,
    pub(crate) clay: Clay,
    pub(crate) current_state: CurrentState,
    pub(crate) glaze_description: Option<String>,
    pub(crate) images: Images,
    pub(crate) created_at: NaiveDateTime,
}

#[derive(Deserialize, Debug)]
pub(crate) struct PutWork {
    pub(crate) project_id: i32,
    pub(crate) name: String,
    pub(crate) notes: Option<String>,
    pub(crate) clay_id: i32,
    pub(crate) glaze_description: Option<String>,
    pub(crate) thumbnail: Option<String>,
    pub(crate) header: Option<String>,
}

#[derive(Serialize)]
pub(crate) struct Images {
    pub(crate) header: Option<String>,
    pub(crate) thumbnail: Option<String>,
}

#[derive(Serialize)]
pub(crate) struct Event {
    pub(crate) id: i32,
    pub(crate) work: ApiResourceReference,
    pub(crate) previous_state: Option<State>,
    pub(crate) current_state: State,
    pub(crate) created_at: NaiveDateTime,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_is_valid_transition() {
        assert!(is_valid_transition(State::Recycled, State::Thrown));

        // Test invalid transitions to Thrown
        let other_states = vec![
            State::Trimming,
            State::AwaitingBisqueFiring,
            State::AwaitingGlazeFiring,
            State::Finished,
        ];
        for state in other_states {
            assert!(!is_valid_transition(state, State::Thrown));
        }

        // Trimming can only be reached from the thrown state.
        assert!(is_valid_transition(State::Thrown, State::Trimming));

        // Bisque can only be reached from Trimming.
        assert!(is_valid_transition(
            State::Trimming,
            State::AwaitingBisqueFiring
        ));

        // Glaze can only be reached from Bisque.
        assert!(is_valid_transition(
            State::AwaitingBisqueFiring,
            State::AwaitingGlazeFiring
        ));

        // Finished can only be reached from Glaze.
        assert!(is_valid_transition(
            State::AwaitingGlazeFiring,
            State::Finished
        ));

        // Recycled can be reached from any state except finished and no initial start state.
        let valid_recycled_previous_states = vec![
            State::Thrown,
            State::Trimming,
            State::AwaitingBisqueFiring,
            State::AwaitingGlazeFiring,
        ];
        for state in valid_recycled_previous_states {
            assert!(is_valid_transition(state, State::Recycled));
        }
        assert!(!is_valid_transition(State::Finished, State::Recycled));
    }
}
