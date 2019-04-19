﻿#region Copyright Simple Injector Contributors
/* The Simple Injector is an easy-to-use Inversion of Control library for .NET
 * 
 * Copyright (c) 2013-2019 Simple Injector Contributors
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and 
 * associated documentation files (the "Software"), to deal in the Software without restriction, including 
 * without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
 * copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the 
 * following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all copies or substantial 
 * portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT 
 * LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO 
 * EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE 
 * USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
#endregion

namespace SimpleInjector.Integration.Web
{
    using System;
    using System.Collections.Generic;
    using System.Web;

    /// <summary>
    /// Defines a lifestyle that caches instances during the execution of a single HTTP Web Request.
    /// Unless explicitly stated otherwise, instances created by this lifestyle will be disposed at the end
    /// of the web request.
    /// </summary>
    /// <example>
    /// The following example shows the usage of the <b>WebRequestLifestyle</b> class:
    /// <code lang="cs"><![CDATA[
    /// var container = new Container();
    /// container.Options.DefaultScopedLifestyle = new WebRequestLifestyle();
    /// container.Register<IUnitOfWork, EntityFrameworkUnitOfWork>(Lifestyle.Scoped);
    /// ]]></code>
    /// </example>
    public sealed class WebRequestLifestyle : ScopedLifestyle
    {
        private static readonly object ScopeKey = new object();

        /// <summary>Initializes a new instance of the <see cref="WebRequestLifestyle"/> class. The instance
        /// will ensure that created and cached instance will be disposed after the execution of the web
        /// request ended and when the created object implements <see cref="IDisposable"/>.</summary>
        public WebRequestLifestyle() : base("Web Request")
        {
        }

        /// <summary>Initializes a new instance of the <see cref="WebRequestLifestyle"/> class.</summary>
        /// <param name="disposeInstanceWhenWebRequestEnds">
        /// Specifies whether the created and cached instance will be disposed after the execution of the web
        /// request ended and when the created object implements <see cref="IDisposable"/>. 
        /// </param>
        [Obsolete("This constructor has been deprecated. Please use WebRequestLifestyle() instead.",
            error: true)]
        [System.ComponentModel.EditorBrowsable(System.ComponentModel.EditorBrowsableState.Never)]
        public WebRequestLifestyle(bool disposeInstanceWhenWebRequestEnds) : this()
        {
            throw new NotSupportedException(
                "This constructor has been deprecated. Please use WebRequestLifestyle() instead.");
        }

        /// <summary>
        /// Allows registering an <paramref name="action"/> delegate that will be called when the scope ends,
        /// but before the scope disposes any instances.
        /// </summary>
        /// <param name="container">The <see cref="Container"/> instance.</param>
        /// <param name="action">The delegate to run when the scope ends.</param>
        /// <exception cref="ArgumentNullException">Thrown when one of the arguments is a null reference
        /// (Nothing in VB).</exception>
        /// <exception cref="InvalidOperationException">Will be thrown when the current thread isn't running
        /// in the context of a web request.</exception>
        [Obsolete("WhenCurrentRequestEnds has been deprecated. " +
            "Please use Lifestyle.Scoped.WhenScopeEnds(Container, Action) instead.",
            error: true)]
        [System.ComponentModel.EditorBrowsable(System.ComponentModel.EditorBrowsableState.Never)]
        public static void WhenCurrentRequestEnds(Container container, Action action)
        {
            throw new NotSupportedException(
                "WhenCurrentRequestEnds has been deprecated. " +
                "Please use Lifestyle.Scoped.WhenScopeEnds(Container, Action) instead.");
        }

        internal static void CleanUpWebRequest(HttpContext context)
        {
            Requires.IsNotNull(context, nameof(context));

            // NOTE: We explicitly don't remove the scopes from the items dictionary, because if anything
            // is resolved from the container after this point during the request, that would cause the
            // creation of a new Scope that will never be disposed. This would make it seem like the
            // application is working, while instead we are failing silently. By not removing the scope,
            // this will cause it to throw an ObjectDisposedException once it is accessed after
            // this point; effectively making the application to fail fast.
            var scopes = (List<Scope>)context.Items[ScopeKey];

            if (!(scopes is null))
            {
                DisposeScopes(scopes);
            }
        }

        /// <summary>
        /// Returns the current <see cref="Scope"/> for this lifestyle and the given 
        /// <paramref name="container"/>, or null when this method is executed outside the context of a scope.
        /// </summary>
        /// <param name="container">The container instance that is related to the scope to return.</param>
        /// <returns>A <see cref="Scope"/> instance or null when there is no scope active in this context.</returns>
        protected override Scope GetCurrentScopeCore(Container container) => GetOrCreateScope(container);

        /// <summary>
        /// Creates a delegate that upon invocation return the current <see cref="Scope"/> for this
        /// lifestyle and the given <paramref name="container"/>, or null when the delegate is executed outside
        /// the context of such scope.
        /// </summary>
        /// <param name="container">The container for which the delegate gets created.</param>
        /// <returns>A <see cref="Func{T}"/> delegate. This method never returns null.</returns>
        protected override Func<Scope> CreateCurrentScopeProvider(Container container)
        {
            Requires.IsNotNull(container, nameof(container));

            return () => GetOrCreateScope(container);
        }

        private static Scope GetOrCreateScope(Container container)
        {
            HttpContext context = HttpContext.Current;

            if (context is null)
            {
                return null;
            }

            // The assumption is that there will only be a very limited set of containers used per request
            // (typically just one), which makes using a List<T> much faster (and less memory intensive)
            // than using a dictionary.
            var scopes = (List<Scope>)context.Items[ScopeKey];

            if (scopes is null)
            {
                context.Items[ScopeKey] = scopes = new List<Scope>(capacity: 2);
            }

            var scope = FindScopeForContainer(scopes, container);

            if (scope is null)
            {
                scopes.Add(scope = new Scope(container));
            }

            return scope;
        }

        private static Scope FindScopeForContainer(List<Scope> scopes, Container container)
        {
            foreach (var scope in scopes)
            {
                if (scope.Container == container)
                {
                    return scope;
                }
            }

            return null;
        }

        private static void DisposeScopes(List<Scope> scopes)
        {
            if (scopes.Count != 1)
            {
                DisposeScopesInReverseOrder(scopes);
            }
            else
            {
                // Optimization: don't create a master scope if there is only one scope (the common case).
                scopes[0].Dispose();
            }
        }

        private static void DisposeScopesInReverseOrder(List<Scope> scopes)
        {
            // Here we use a 'master' scope that will hold the real scopes. This allows all scopes
            // to be disposed, even if a scope's Dispose method throws an exception. Scopes will
            // also be disposed in opposite order of creation.
            using (var masterScope = new Scope())
            {
                foreach (var scope in scopes)
                {
                    masterScope.RegisterForDisposal(scope);
                }
            }
        }
    }
}