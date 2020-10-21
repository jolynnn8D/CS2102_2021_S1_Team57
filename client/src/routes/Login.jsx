import React, { useState } from 'react'
import { AppBar, Toolbar, Container, TextField, Card, Typography, Button } from '@material-ui/core'
import { makeStyles } from '@material-ui/core/styles';
import { classnames } from '@material-ui/data-grid';

const useStyles = makeStyles((theme) => ({
    paper: {
      marginTop: theme.spacing(8),
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
    },
    avatar: {
      margin: theme.spacing(1),
      backgroundColor: theme.palette.secondary.main,
    },
    form: {
      width: '100%', // Fix IE 11 issue.
      marginTop: theme.spacing(1),
    },
    submit: {
      margin: theme.spacing(3, 0, 2),
    },
    container: {
        marginTop: theme.spacing(15),
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
    },
    textfield: {
        marginTop: theme.spacing(3),
        marginBottom: theme.spacing(3),
    },
  }));

const Login = () => {
    const classes = useStyles();
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');

    return (
        <div>
            <Container component="main" maxWidth="xs" className={classes.container}>
            <Typography component="h1" variant="h3" color="textPrimary" align="center">
                Login
            </Typography>
            <form className={classes.form} noValidate>
                <TextField 
                    variant="outlined"
                    label="Username"
                    required
                    fullWidth
                    id="username"
                    autoComplete="username"
                    autoFocus
                    className={classes.textfield}
                    onChange={(event) => setUsername(event.target.value)}
                />
                <TextField
                    variant="outlined"
                    label="Password"
                    required
                    fullWidth
                    id="password"
                    autoComplete="password"
                    autoFocus
                    className={classes.textfield}
                    onChange={(event)=>setPassword(event.target.value)}
                />
                <Button
                    type="submit"
                    fullWidth
                    variant="contained"
                    color="primary"
                    className={classes.submit}
                >
                    Login
                </Button>
                <Typography variant="h3">
                    {username}
                </Typography>
                <Typography variant="h3">
                    {password}
                </Typography>
            </form>
        </Container>
        </div>
    )
}

export default Login