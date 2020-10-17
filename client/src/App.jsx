import React from "react";
import { BrowserRouter as Router, Switch, Route } from "react-router-dom";
import Homepage from "./routes/Homepage"
import Updatepage from "./routes/Updatepage"
import Userdetailpage from "./routes/Userdetailpage"
import { UsersContextProvider } from "./context/UsersContext";
import Adminpage from "./routes/Adminpage";
import SetPricepage from "./routes/SetPricepage";
import ViewAllCaretakers from "./components/admin/ViewAllCaretakers";
import ViewCaretakerspage from "./routes/ViewCaretakerspage";
import UserProfile from "./routes/UserProfile";

const App = () => {
    return (
        <UsersContextProvider>
            <div className="container">
                <Router>
                    <Switch>
                        <Route exact path="/" component={Homepage} />
                        <Route exact path="/admin" component={Adminpage}/>
                        <Route exact path="/admin/set-price" component={SetPricepage}/>
                        <Route exact path="/admin/view-caretakers" component={ViewCaretakerspage}/>
                        <Route exact path="/users/:id/update" component={Updatepage} />
                        <Route exact path="/users/:id" component={Userdetailpage} />
                        <Route exact path="/userprofile" component={UserProfile}/>
                    </Switch>
                </Router>
            </div>
        </UsersContextProvider>
    )
};

export default App;